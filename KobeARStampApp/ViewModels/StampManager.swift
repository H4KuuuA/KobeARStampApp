//
//  StampManager.swift
//  KobeARStampApp
//
//  DB連携対応版
//

import SwiftUI
import CoreLocation

@MainActor
class StampManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = StampManager()
    
    // MARK: - Properties

    
    /// スポットのリスト(DBから取得)
    @Published var allSpots: [Spot] = []
    
    /// 現在選択中のイベントに紐づくスポット
    @Published var currentEventSpots: [Spot] = []
    
    /// 取得済みスタンプ(ローカル保存)
    @Published var acquiredStamps: [UUID: AcquiredStamp] = [:]
    
    /// ローディング状態
    @Published var isLoadingSpots = false
    
    /// イベント別スポット取得中
    @Published var isLoadingEventSpots = false
    
    /// 現在開催中のイベント
    @Published var currentEvent: Event?
    
    // MARK: - Computed Properties
    
    var acquiredStampCount: Int {
        acquiredStamps.count
    }
    
    var totalSpotCount: Int {
        allSpots.count
    }
    
    /// 現在選択中のイベントのスポット数（StampCardView用）
    var currentEventSpotCount: Int {
        currentEventSpots.count
    }
    
    /// 現在選択中のイベントで取得済みのスタンプ数
    var currentEventAcquiredCount: Int {
        let eventSpotIds = Set(currentEventSpots.map { $0.id })
        return acquiredStamps.keys.filter { eventSpotIds.contains($0) }.count
    }
    
    var progress: Float {
        guard totalSpotCount > 0 else { return 0 }
        return Float(acquiredStampCount) / Float(totalSpotCount)
    }
    
    var progressText: String {
        "\(acquiredStampCount) / \(totalSpotCount)"
    }
    
    // MARK: - File Management
    
    private let stampsDirectoryURL: URL
    private let stampsJSONURL: URL
    
    // MARK: - Initialization
    
    private init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        stampsDirectoryURL = documentsURL.appendingPathComponent("StampImages")
        stampsJSONURL = documentsURL.appendingPathComponent("stamps.json")
        
        try? FileManager.default.createDirectory(
            at: stampsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        // ログイン前はデフォルトスポットを使用
        allSpots = Self.defaultSpots
        loadStamps() // ← スタンプは先に読み込む
        
        // 認証状態を監視してスポットを読み込む
        setupAuthObserver()
    }
    
    // MARK: - Auth Observer
    
    /// 認証状態を監視してスポットを読み込む
    private func setupAuthObserver() {
        Task {
            // AuthManagerの状態変化を監視
            for await _ in NotificationCenter.default.notifications(named: .authStateChanged) {
                if AuthManager.shared.isAuthenticated {
                    await loadSpotsFromDatabase()
                } else {
                    // ログアウト時はデフォルトスポットに戻す
                    allSpots = Self.defaultSpots
                }
            }
        }
    }
    
    // MARK: - Data Loading
    
    /// DBからスポットを非同期で読み込む
    func loadSpotsFromDatabase() async {
        isLoadingSpots = true
        
        do {
            let spots = try await DataRepository.shared.fetchActiveSpots()
            allSpots = spots.isEmpty ? Self.defaultSpots : spots
            print("✅ DBからスポット読み込み成功: \(spots.count)件")
        } catch {
            print("⚠️ スポット読み込み失敗、デフォルトを使用: \(error)")
            allSpots = Self.defaultSpots
        }
        
        isLoadingSpots = false
    }
    
    /// DBからスポットを取得（外部から呼び出し可能）
    func fetchSpots() async {
        await loadSpotsFromDatabase()
    }
    
    /// 特定のイベントに紐づくスポットを取得
    func fetchSpots(for event: Event) async {
        isLoadingEventSpots = true
        
        do {
            print("📥 Fetching spots for event: \(event.name)")
            
            // event_spotテーブルから該当イベントのスポットIDを取得
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
            
            print("📥 Found \(spotIds.count) spot IDs for event")
            
            // 取得したIDに該当するスポットをallSpotsからフィルタリング
            currentEventSpots = allSpots.filter { spotIds.contains($0.id) }
            
            print("✅ Event spots fetched: \(currentEventSpots.count)")
            
        } catch {
            print("❌ Error fetching event spots: \(error)")
            // エラー時は空配列にする
            currentEventSpots = []
        }
        
        isLoadingEventSpots = false
    }
    
    // MARK: - Spot Management
    
    /// DBからスポットを取得（後方互換性のため残す）
    func fetchSpotsFromDB() async throws {
        isLoadingSpots = true
        
        let spots = try await DataRepository.shared.fetchActiveSpots()
        
        self.allSpots = spots
        self.isLoadingSpots = false
    }
    
    /// スポットIDからSpotを取得
    func getSpot(by id: UUID) -> Spot? {
        return allSpots.first { $0.id == id }
    }
    
    // MARK: - Stamp Management
    
    /// スタンプを追加(トランザクション的)
    func addStamp(image: UIImage, for spot: Spot) {
        // 1. 既に取得済みかチェック
        guard acquiredStamps[spot.id] == nil else {
            print("⚠️ スタンプは既に取得済み: \(spot.name)")
            return
        }
        
        // 2. Spotが有効か検証(DBから削除されていないか)
        guard getSpot(by: spot.id) != nil else {
            print("❌ 無効なスポット: \(spot.id)")
            return
        }
        
        // 3. 画像を保存
        let fileName = spot.id.uuidString + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 画像のJPEG変換に失敗")
            return
        }
        
        do {
            try data.write(to: fileURL)
            
            // 4. メタデータを保存
            // ⚠️ 一時的にダミーのuserIdを使用(ログイン機能実装後に修正)
            let userId = UUID() // TODO: AuthService.shared.currentUser?.id を使用
            
            let newStamp = AcquiredStamp(
                id: UUID(),
                userId: userId,
                spotId: spot.id,
                eventId: nil,
                latitude: nil,
                longitude: nil,
                visitedAt: Date(),
                spotNameSnapshot: spot.name,
                eventNameSnapshot: nil
            )
            
            acquiredStamps[spot.id] = newStamp
            saveStamps()
            
            print("✅ スタンプを保存: \(spot.name)")
            
            // 5. サーバーに同期(ログイン機能実装後に有効化)
            // Task {
            //     do {
            //         try await DataRepository.shared.checkIn(
            //             spotId: spot.id,
            //             latitude: 0, // TODO: 実際の位置情報を渡す
            //             longitude: 0
            //         )
            //     } catch {
            //         print("⚠️ サーバー同期失敗: \(error)")
            //     }
            // }
            
        } catch {
            print("❌ 画像保存失敗: \(error.localizedDescription)")
        }
    }
    
    /// スタンプが取得済みかチェック
    func isStampAcquired(spotID: UUID) -> Bool {
        return acquiredStamps[spotID] != nil
    }
    
    // MARK: - Image Retrieval
    
    /// AcquiredStampから画像を取得
    func getImage(for stamp: AcquiredStamp) -> UIImage? {
        let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    /// Spotから画像を取得(取得済みの場合のみ)
    func getImage(for spot: Spot) -> UIImage? {
        guard let stamp = acquiredStamps[spot.id] else {
            return nil
        }
        return getImage(for: stamp)
    }
    
    // MARK: - Persistence (Local)
    
    /// スタンプリストをJSONに保存
    private func saveStamps() {
        do {
            let data = try JSONEncoder().encode(acquiredStamps)
            try data.write(to: stampsJSONURL)
            print("✅ スタンプリストを保存")
        } catch {
            print("❌ スタンプリスト保存失敗: \(error.localizedDescription)")
        }
    }
    
    /// スタンプリストをJSONから読み込み
    private func loadStamps() {
        guard let data = try? Data(contentsOf: stampsJSONURL) else {
            print("ℹ️ スタンプリストが見つかりません(初回起動)")
            return
        }
        
        do {
            acquiredStamps = try JSONDecoder().decode([UUID: AcquiredStamp].self, from: data)
            print("✅ スタンプリストを読み込み: \(acquiredStamps.count)個")
            
            // DBから削除されたSpotのスタンプをクリーンアップ
            cleanupOrphanedStamps()
            
        } catch {
            print("❌ スタンプリスト読み込み失敗: \(error.localizedDescription)")
        }
    }
    
    /// DBから削除されたスポットのスタンプを削除
    private func cleanupOrphanedStamps() {
        let validSpotIDs = Set(allSpots.map { $0.id })
        let orphanedStampIDs = acquiredStamps.keys.filter { !validSpotIDs.contains($0) }
        
        for stampID in orphanedStampIDs {
            if let stamp = acquiredStamps[stampID] {
                let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
                try? FileManager.default.removeItem(at: fileURL)
                acquiredStamps.removeValue(forKey: stampID)
                print("🧹 孤立したスタンプを削除: \(stampID)")
            }
        }
        
        if !orphanedStampIDs.isEmpty {
            saveStamps()
        }
    }
    
    // MARK: - Category Filtering
    
    func getSpots(by category: String) -> [Spot] {
        return allSpots.filter { $0.category == category }
    }
    
    var allCategories: [String] {
        let categories = allSpots.compactMap { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // MARK: - Event Management
    
    /// Supabaseから現在開催中のイベントを取得
    func fetchCurrentEvent() async {
        print("📥 Fetching current event from Supabase...")
        
        do {
            let now = Date()
            let formatter = ISO8601DateFormatter()
            let nowString = formatter.string(from: now)
            
            print("📥 Current time: \(nowString)")
            
            // 現在開催中のイベントを取得（1件のみ）
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
            print("✅ Current event fetched: \(events.first?.name ?? "None")")
            
        } catch {
            print("❌ Error fetching current event: \(error)")
            self.currentEvent = nil
        }
    }
    
    // MARK: - Debug
    
    #if DEBUG
    func resetAllStamps() {
        for stamp in acquiredStamps.values {
            let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        acquiredStamps.removeAll()
        saveStamps()
        print("🔄 全スタンプをリセットしました")
    }
    
    /// デバッグ用: プレースホルダー画像を使って特定のスポットのスタンプを取得済みにする
    func debugAcquireStamp(spotID: UUID) {
        guard let spot = getSpot(by: spotID) else {
            print("❌ スポットが見つかりません: \(spotID)")
            return
        }
        
        // プレースホルダー画像を取得
        guard let placeholderImage = UIImage(named: spot.placeholderImageName) else {
            print("❌ プレースホルダー画像が見つかりません: \(spot.placeholderImageName)")
            return
        }
        
        // スタンプとして保存
        addStamp(image: placeholderImage, for: spot)
        print("✅ デバッグ: \(spot.name) のスタンプを取得しました")
    }
    
    /// デバッグ用: 最初のスポットのスタンプを取得済みにする
    func debugAcquireFirstStamp() {
        guard let firstSpot = allSpots.first else {
            print("❌ スポットが存在しません")
            return
        }
        debugAcquireStamp(spotID: firstSpot.id)
    }
    
    /// デバッグ用: 複数のスポットをまとめて取得済みにする
    func debugAcquireMultipleStamps(spotIDs: [UUID]) {
        for spotID in spotIDs {
            debugAcquireStamp(spotID: spotID)
        }
    }
    
    /// デバッグ用: ランダムに指定数のスタンプを取得する
    func debugAcquireRandomStamps(count: Int) {
        let availableSpots = allSpots.filter { !isStampAcquired(spotID: $0.id) }
        let spotsToAcquire = availableSpots.shuffled().prefix(count)
        
        for spot in spotsToAcquire {
            debugAcquireStamp(spotID: spot.id)
        }
    }
    #endif
}

// MARK: - Default Spots (テスト用データ)

extension StampManager {
    static let defaultSpots: [Spot] = [
        // ⚠️ 注意: 本番ではDBから取得するため、このデータは削除予定
        // 現在はテスト用として残しています
        
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
