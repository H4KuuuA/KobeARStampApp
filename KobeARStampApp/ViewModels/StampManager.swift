//
//  StampManager.swift
//  Supabaseベース(CoreData削除済み)
//

import SwiftUI
import CoreLocation

@MainActor
class StampManager: ObservableObject {
    
    static let shared = StampManager()
    
    // MARK: - Properties
    
    @Published var allSpots: [Spot] = []
    @Published var currentEventSpots: [Spot] = []
    
    /// 取得済みスポットのID(メモリキャッシュ)
    @Published var acquiredSpotIds: Set<UUID> = []
    
    /// 画像キャッシュ
    @Published var imageCache: [UUID: UIImage] = [:]
    
    @Published var isLoadingSpots = false
    @Published var isLoadingEventSpots = false
    @Published var isLoadingVisits = false
    @Published var currentEvent: Event?
    
    // MARK: - Computed Properties
    
    var acquiredStampCount: Int {
        acquiredSpotIds.count
    }
    
    var totalSpotCount: Int {
        allSpots.count
    }
    
    var currentEventSpotCount: Int {
        currentEventSpots.count
    }
    
    var currentEventAcquiredCount: Int {
        let eventSpotIds = Set(currentEventSpots.map { $0.id })
        return acquiredSpotIds.filter { eventSpotIds.contains($0) }.count
    }
    
    var progress: Float {
        guard totalSpotCount > 0 else { return 0 }
        return Float(acquiredStampCount) / Float(totalSpotCount)
    }
    
    // MARK: - File Management (画像のみローカル保存)
    
    private let stampsDirectoryURL: URL
    
    // MARK: - Initialization
    
    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        stampsDirectoryURL = documentsURL.appendingPathComponent("StampImages")
        
        try? FileManager.default.createDirectory(
            at: stampsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        allSpots = Self.defaultSpots
        
        // 起動時にSupabaseから訪問履歴を取得
        Task {
            await loadVisitsFromSupabase()
            await loadImageCache()
        }
        
        setupAuthObserver()
    }
    
    // MARK: - Supabase Integration
    
    /// Supabaseから訪問履歴を取得
    func loadVisitsFromSupabase() async {
        guard AuthManager.shared.isAuthenticated else {
            print("ℹ️ 未ログイン - 訪問履歴なし")
            return
        }
        
        isLoadingVisits = true
        
        do {
            // 現在のユーザーIDを取得
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            // spot_visitテーブルから取得
            let response = try await SupabaseManager.shared.client
                .from("spot_visit")
                .select("spot_id")
                .eq("user_id", value: userId.uuidString)
                .execute()
            
            struct SpotVisitResponse: Codable {
                let spot_id: String
            }
            
            let visits = try JSONDecoder().decode([SpotVisitResponse].self, from: response.data)
            let spotIds = visits.compactMap { UUID(uuidString: $0.spot_id) }
            
            acquiredSpotIds = Set(spotIds)
            print("✅ 訪問履歴をSupabaseから取得: \(spotIds.count)件")
            
        } catch {
            print("❌ 訪問履歴取得エラー: \(error.localizedDescription)")
        }
        
        isLoadingVisits = false
    }
    
    /// Supabaseにチェックインを記録
    func recordCheckIn(for spot: Spot, event: Event? = nil, latitude: Double? = nil, longitude: Double? = nil) async throws {
        guard AuthManager.shared.isAuthenticated else {
            throw NSError(domain: "StampManager", code: 401, userInfo: [NSLocalizedDescriptionKey: "ログインが必要です"])
        }
        
        let userId = try await SupabaseManager.shared.client.auth.session.user.id
        
        // Encodable準拠の構造体を使用
        struct SpotVisitInsert: Encodable {
            let user_id: String
            let spot_id: String
            let event_id: String?
            let latitude: Double?
            let longitude: Double?
            let visited_at: String
        }
        
        let visit = SpotVisitInsert(
            user_id: userId.uuidString,
            spot_id: spot.id.uuidString,
            event_id: event?.id.uuidString,
            latitude: latitude,
            longitude: longitude,
            visited_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await SupabaseManager.shared.client
            .from("spot_visit")
            .insert(visit)
            .execute()
        
        print("✅ チェックイン記録: \(spot.name)")
    }
    
    // MARK: - Stamp Management
    
    /// スタンプを取得(画像保存 + Supabase記録)
    func addStamp(image: UIImage, for spot: Spot, event: Event? = nil, latitude: Double? = nil, longitude: Double? = nil) async {
        // 1. 既に取得済みかチェック
        guard !acquiredSpotIds.contains(spot.id) else {
            print("⚠️ スタンプは既に取得済み: \(spot.name)")
            return
        }
        
        // 2. 画像をローカルに保存
        let fileName = spot.id.uuidString + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 画像のJPEG変換に失敗")
            return
        }
        
        do {
            try data.write(to: fileURL)
            
            // 3. メモリキャッシュに追加
            acquiredSpotIds.insert(spot.id)
            imageCache[spot.id] = image
            
            print("✅ 画像を保存: \(spot.name)")
            print("   パス: \(fileURL.path)")
            
            // 4. Supabaseに記録
            try await recordCheckIn(for: spot, event: event, latitude: latitude, longitude: longitude)
            
            objectWillChange.send()
            
        } catch {
            print("❌ スタンプ保存失敗: \(error.localizedDescription)")
            
            // ロールバック
            acquiredSpotIds.remove(spot.id)
            imageCache.removeValue(forKey: spot.id)
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    /// スタンプが取得済みかチェック
    func isStampAcquired(spotID: UUID) -> Bool {
        return acquiredSpotIds.contains(spotID)
    }
    
    /// Spotから画像を取得
    func getImage(for spot: Spot) -> UIImage? {
        // キャッシュにあればそれを返す
        if let cachedImage = imageCache[spot.id] {
            return cachedImage
        }
        
        // ディスクから読み込み
        let fileName = spot.id.uuidString + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }
        
        // キャッシュに保存
        imageCache[spot.id] = image
        return image
    }
    
    // MARK: - Image Cache
    
    /// 画像キャッシュを読み込み
    private func loadImageCache() async {
        print("🖼️ 画像キャッシュ読み込み開始...")
        var loadedCount = 0
        
        for spotId in acquiredSpotIds {
            let fileName = spotId.uuidString + ".jpeg"
            let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
            
            if let data = try? Data(contentsOf: fileURL),
               let image = UIImage(data: data) {
                await MainActor.run {
                    imageCache[spotId] = image
                }
                loadedCount += 1
            }
        }
        
        print("✅ 画像キャッシュ読み込み完了: \(loadedCount)枚")
    }
    
    // MARK: - Auth Observer
    
    private func setupAuthObserver() {
        Task {
            for await _ in NotificationCenter.default.notifications(named: .authStateChanged) {
                if AuthManager.shared.isAuthenticated {
                    await loadSpotsFromDatabase()
                    await loadVisitsFromSupabase()
                } else {
                    allSpots = Self.defaultSpots
                    acquiredSpotIds.removeAll()
                    imageCache.removeAll()
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadSpotsFromDatabase() async {
        isLoadingSpots = true
        
        do {
            let spots = try await DataRepository.shared.fetchActiveSpots()
            allSpots = spots.isEmpty ? Self.defaultSpots : spots
            print("✅ DBからスポット読み込み成功: \(spots.count)件")
        } catch {
            print("⚠️ スポット読み込み失敗: \(error)")
            allSpots = Self.defaultSpots
        }
        
        isLoadingSpots = false
    }
    
    func fetchSpots() async {
        await loadSpotsFromDatabase()
    }
    
    func fetchSpots(for event: Event) async {
        isLoadingEventSpots = true
        
        do {
            let response = try await SupabaseManager.shared.client
                .from("event_spot")
                .select("spot_id")
                .eq("event_id", value: event.id.uuidString)
                .execute()
            
            struct EventSpotRelation: Codable {
                let spot_id: String
            }
            
            let decoder = JSONDecoder()
            let relations = try decoder.decode([EventSpotRelation].self, from: response.data)
            let spotIds = relations.compactMap { UUID(uuidString: $0.spot_id) }
            
            if spotIds.isEmpty {
                currentEventSpots = []
            } else {
                let spotsResponse = try await SupabaseManager.shared.client
                    .from("spots")
                    .select()
                    .in("id", values: spotIds.map { $0.uuidString })
                    .eq("is_active", value: true)
                    .execute()
                
                let spotsDecoder = JSONDecoder()
                spotsDecoder.dateDecodingStrategy = .iso8601
                currentEventSpots = try spotsDecoder.decode([Spot].self, from: spotsResponse.data)
            }
            
            print("✅ Event spots fetched: \(currentEventSpots.count)")
            
        } catch {
            print("❌ Error fetching event spots: \(error)")
            currentEventSpots = []
        }
        
        isLoadingEventSpots = false
    }
    
    func getSpot(by id: UUID) -> Spot? {
        return allSpots.first { $0.id == id }
    }
    
    func getSpots(by category: String) -> [Spot] {
        return allSpots.filter { $0.category == category }
    }
    
    var allCategories: [String] {
        let categories = allSpots.compactMap { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    func fetchCurrentEvent() async {
        print("📥 Fetching current event...")
        
        do {
            let now = Date()
            let formatter = ISO8601DateFormatter()
            let nowString = formatter.string(from: now)
            
            let response = try await SupabaseManager.shared.client
                .from("events")
                .select()
                .eq("status", value: true)
                .eq("is_public", value: true)
                .lte("start_time", value: nowString)
                .gte("end_time", value: nowString)
                .order("start_time", ascending: false)
                .limit(1)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let events = try decoder.decode([Event].self, from: response.data)
            self.currentEvent = events.first
            print("✅ Current event: \(events.first?.name ?? "None")")
            
        } catch {
            print("❌ Error fetching current event: \(error)")
            self.currentEvent = nil
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    func resetAllStamps() async {
        // ローカル画像を削除
        for spotId in acquiredSpotIds {
            let fileName = spotId.uuidString + ".jpeg"
            let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        acquiredSpotIds.removeAll()
        imageCache.removeAll()
        
        // Supabaseから削除
        if AuthManager.shared.isAuthenticated {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                try await SupabaseManager.shared.client
                    .from("spot_visit")
                    .delete()
                    .eq("user_id", value: userId.uuidString)
                    .execute()
                
                print("🔄 Supabaseの訪問履歴を削除")
            } catch {
                print("❌ 削除エラー: \(error)")
            }
        }
        
        print("🔄 全スタンプをリセットしました")
    }
    #endif
}

// MARK: - Default Spots

extension StampManager {
    static let defaultSpots: [Spot] = [
        Spot(
            id: UUID(),
            name: "灘駅北口広場",
            subtitle: "灘駅北側の待ち合わせ広場",
            description: "灘駅の北口にある広場。集合や待ち合わせに便利なスポットです。",
            address: "兵庫県神戸市灘区",
            latitude: 34.70622423097614,
            longitude: 135.21616725739096,
            radius: 50,
            category: "公園",
            pinColor: "#FF0000",
            imageUrl: "https://example.com/images/nada_north_plaza.png",
            arModelId: nil,
            isActive: true,
            createdByUser: nil,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil
        )
    ]
}
