//
//  DataRepository.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/16.
//


import Foundation
import Supabase

/// データベース操作を一元管理するリポジトリクラス
/// 各画面から直接Supabaseクライアントを呼ぶのではなく、
/// このクラスを経由することで、コードの再利用性とメンテナンス性を向上させます
class DataRepository {
    // MARK: - Singleton
    
    static let shared = DataRepository()
    private let client = SupabaseManager.shared.client
    private init() {}
    
    // MARK: - Authentication
    
    /// サインアップ（メールアドレス + パスワード）
    func signUp(email: String, password: String) async throws -> AuthResponse {
        return try await client.auth.signUp(email: email, password: password)
    }
    
    /// サインイン（メールアドレス + パスワード）
    func signIn(email: String, password: String) async throws -> Session {
        return try await client.auth.signIn(email: email, password: password)
    }
    
    /// サインアウト
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// 現在のユーザーを取得
    func getCurrentUser() async throws -> User? {
        return try await client.auth.session.user
    }
    
    /// 現在のセッションを取得
    func getCurrentSession() -> Session? {
        return client.auth.currentSession
    }
    
    // MARK: - User Profile Management
    
    /// ユーザープロフィールを作成（サインアップ後に呼ばれる）
    /// 注意: handle_new_user トリガーが既に user_profile を作成している場合、
    /// このメソッドではなく updateUserProfile を使用してください
    func createUserProfile(profile: UserProfile) async throws {
        struct ProfileInsert: Encodable {
            let user_id: String
            let email: String
            let role: String
            let gender: Int?
            let address: String?
            let birth_date: String?
            let is_active: Bool
            let last_login_at: String?
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        let loginFormatter = ISO8601DateFormatter()
        
        let insert = ProfileInsert(
            user_id: profile.userId.uuidString,
            email: profile.email,
            role: profile.role,
            gender: profile.gender,
            address: profile.address,
            birth_date: profile.birthDate,
            is_active: profile.isActive,
            last_login_at: profile.lastLoginAt.map { loginFormatter.string(from: $0) }
        )
        
        try await client.from("user_profile").insert(insert).execute()
        print("✅ ユーザープロフィール作成成功: \(profile.email)")
    }
    
    /// ユーザープロフィールを取得
    func fetchUserProfile(userId: UUID) async throws -> UserProfile {
        let profile: UserProfile = try await client
            .from("user_profile")
            .select()
            .eq("user_id", value: userId.uuidString)
            .single()
            .execute()
            .value
        return profile
    }
    
    /// ユーザープロフィールを更新
    func updateUserProfile(
        userId: UUID,
        username: String? = nil,
        gender: Int? = nil,
        address: String? = nil,
        birthDate: Date? = nil
    ) async throws {
        struct ProfileUpdate: Encodable {
            let username: String?
            let gender: Int?
            let address: String?
            let birth_date: String?
            let updated_at: String
        }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        let update = ProfileUpdate(
            username: username,
            gender: gender,
            address: address,
            birth_date: birthDate.map { formatter.string(from: $0) },
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await client
            .from("user_profile")
            .update(update)
            .eq("user_id", value: userId.uuidString)
            .execute()
        
        print("✅ ユーザープロフィール更新成功")
    }
    
    // MARK: - Spots（スポット操作）
    
    /// 公開中のスポット一覧を取得
    /// - Returns: アクティブなスポットの配列
    /// - Throws: データベースエラー
    func fetchActiveSpots() async throws -> [Spot] {
        let spots: [Spot] = try await client
            .from("spots")
            .select("*")
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ スポット取得成功: \(spots.count)件")
        return spots
    }
    
    /// IDを指定してスポット詳細を取得
    /// - Parameter id: スポットID
    /// - Returns: スポット詳細
    /// - Throws: データベースエラー
    func fetchSpot(id: UUID) async throws -> Spot {
        let spot: Spot = try await client
            .from("spots")
            .select("*")
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        print("✅ スポット詳細取得: \(spot.name)")
        return spot
    }
    
    /// カテゴリでスポットを絞り込み
    /// - Parameter category: カテゴリ名
    /// - Returns: 該当するスポットの配列
    /// - Throws: データベースエラー
    func fetchSpots(byCategory category: String) async throws -> [Spot] {
        let spots: [Spot] = try await client
            .from("spots")
            .select()
            .eq("is_active", value: true)
            .eq("category", value: category)
            .is("deleted_at", value: nil)
            .order("name", ascending: true)
            .execute()
            .value
        
        print("✅ カテゴリ「\(category)」のスポット: \(spots.count)件")
        return spots
    }
    
    /// 位置情報から近くのスポットを検索
    /// - Parameters:
    ///   - latitude: 緯度
    ///   - longitude: 経度
    ///   - radiusKm: 検索範囲（キロメートル）
    /// - Returns: 近くのスポットの配列
    /// - Throws: データベースエラー
    func fetchNearbySpots(
        latitude: Double,
        longitude: Double,
        radiusKm: Double = 5.0
    ) async throws -> [Spot] {
        let allSpots = try await fetchActiveSpots()
        
        let nearbySpots = allSpots.filter { spot in
            let distance = calculateDistance(
                lat1: latitude,
                lon1: longitude,
                lat2: spot.latitude,
                lon2: spot.longitude
            )
            return distance <= radiusKm
        }
        
        print("✅ 近くのスポット: \(nearbySpots.count)件（半径\(radiusKm)km以内）")
        return nearbySpots
    }
    
    // MARK: - AR Models（ARモデル操作）
    
    /// ARモデル情報を取得
    /// - Parameter id: ARモデルID
    /// - Returns: ARモデル
    /// - Throws: データベースエラー、非対応形式エラー
    func fetchArModel(id: UUID) async throws -> ARModel {
        let model: ARModel = try await client
            .from("ar_model")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
        
        guard model.isUSDZ || model.isReality else {
            throw RepositoryError.unsupportedFileFormat(
                format: model.fileExtension,
                message: "このモデルはiOSに対応していません（.usdz または .reality 形式が必要です）"
            )
        }
        
        print("✅ ARモデル取得: \(model.modelName) (\(model.fileExtension))")
        return model
    }
    
    /// スポットに紐づくARモデルを取得
    /// - Parameter spot: スポット
    /// - Returns: ARモデル（存在しない場合はnil）
    /// - Throws: データベースエラー
    func fetchArModel(for spot: Spot) async throws -> ARModel? {
        guard let arModelId = spot.arModelId else { return nil }
        return try await fetchArModel(id: arModelId)
    }
    
    // MARK: - Events（イベント操作）
    
    /// 公開中のイベント一覧を取得
    /// - Returns: 公開イベントの配列
    /// - Throws: データベースエラー
    func fetchPublicEvents() async throws -> [Event] {
        let events: [Event] = try await client
            .from("events")
            .select()
            .eq("is_public", value: true)
            .eq("status", value: true)
            .order("start_time", ascending: false)
            .execute()
            .value
        
        print("✅ イベント取得: \(events.count)件")
        return events
    }
    
    /// 開催中のイベントのみ取得
    /// - Returns: 現在開催中のイベントの配列
    /// - Throws: データベースエラー
    func fetchOngoingEvents() async throws -> [Event] {
        let now = Date()
        let allEvents = try await fetchPublicEvents()
        
        let ongoingEvents = allEvents.filter { event in
            guard let start = event.startTime, let end = event.endTime else {
                return false
            }
            return start <= now && now <= end
        }
        
        print("✅ 開催中のイベント: \(ongoingEvents.count)件")
        return ongoingEvents
    }
    
    /// イベントに紐づくスポット一覧を取得（順序付き）
    /// - Parameter eventId: イベントID
    /// - Returns: スポットの配列
    /// - Throws: データベースエラー
    func fetchEventSpots(eventId: UUID) async throws -> [Spot] {
        let response: [EventSpotWithSpot] = try await client
            .from("event_spot")
            .select("""
                spot_id,
                order_in_event,
                spots!inner(*)
            """)
            .eq("event_id", value: eventId)
            .order("order_in_event", ascending: true)
            .execute()
            .value
        
        let spots = response.map { $0.spots }
        print("✅ イベントのスポット取得: \(spots.count)件")
        return spots
    }
    
    // MARK: - Visits（チェックイン操作）
    
    /// スポットにチェックイン
    /// - Parameters:
    ///   - spotId: スポットID
    ///   - eventId: イベントID（オプション）
    ///   - latitude: 現在地の緯度
    ///   - longitude: 現在地の経度
    /// - Throws: 認証エラー、データベースエラー
    func checkIn(
        spotId: UUID,
        eventId: UUID? = nil,
        latitude: Double,
        longitude: Double
    ) async throws {
        guard let userId = client.auth.currentSession?.user.id else {
            throw RepositoryError.notAuthenticated(message: "チェックインするにはログインが必要です")
        }
        
        struct VisitInsert: Encodable {
            let user_id: UUID
            let spot_id: UUID
            let event_id: UUID?
            let latitude: Double
            let longitude: Double
        }
        
        let visit = VisitInsert(
            user_id: userId,
            spot_id: spotId,
            event_id: eventId,
            latitude: latitude,
            longitude: longitude
        )
        
        try await client.from("spot_visit").insert(visit).execute()
        print("✅ チェックイン完了: スポットID \(spotId)")
    }
    
    /// 自分のチェックイン履歴を取得
    /// - Parameter limit: 取得件数
    /// - Returns: チェックイン履歴
    /// - Throws: 認証エラー、データベースエラー
    func fetchMyVisits(limit: Int = 50) async throws -> [SpotVisit] {
        guard let userId = client.auth.currentSession?.user.id else {
            throw RepositoryError.notAuthenticated(message: "履歴を取得するにはログインが必要です")
        }
        
        let visits: [SpotVisit] = try await client
            .from("spot_visit")
            .select()
            .eq("user_id", value: userId)
            .order("visited_at", ascending: false)
            .limit(limit)
            .execute()
            .value
        
        print("✅ チェックイン履歴取得: \(visits.count)件")
        return visits
    }
    
    /// 特定のスポットに訪問したことがあるかチェック
    /// - Parameter spotId: スポットID
    /// - Returns: 訪問済みの場合true
    /// - Throws: 認証エラー、データベースエラー
    func hasVisited(spotId: UUID) async throws -> Bool {
        guard let userId = client.auth.currentSession?.user.id else {
            return false
        }
        
        let response = try await client
            .from("spot_visit")
            .select("id", head: true, count: .exact)
            .eq("user_id", value: userId)
            .eq("spot_id", value: spotId)
            .limit(1)
            .execute()
        
        return (response.count ?? 0) > 0
    }
    
    /// イベントの進捗状況を取得
    /// - Parameter eventId: イベントID
    /// - Returns: 進捗情報（訪問済みスポット数/全スポット数）
    /// - Throws: データベースエラー
    func fetchEventProgress(eventId: UUID) async throws -> EventProgress {
        // ログインチェックのみ（userIdは後続の hasVisited で使用される）
        guard client.auth.currentSession?.user.id != nil else {
            throw RepositoryError.notAuthenticated(message: "進捗を取得するにはログインが必要です")
        }
        
        let eventSpots = try await fetchEventSpots(eventId: eventId)
        let totalSpots = eventSpots.count
        
        var visitedCount = 0
        for spot in eventSpots {
            if try await hasVisited(spotId: spot.id) {
                visitedCount += 1
            }
        }
        
        let percentage = totalSpots > 0 ? Double(visitedCount) / Double(totalSpots) * 100 : 0
        
        return EventProgress(
            eventId: eventId,
            totalSpots: totalSpots,
            visitedSpots: visitedCount,
            completionPercentage: percentage
        )
    }
    
    // MARK: - AR Model Sync
    
    /// ARモデルが紐づいているアクティブなスポット一覧を取得
    /// - Returns: SpotWithModel の配列（ARモデル情報を含む）
    /// - Throws: データベースエラー
    func fetchSpotsWithARModels() async throws -> [SpotWithModel] {
        let query = client
            .from("spots")
            .select("""
                id,
                name,
                ar_model_id,
                ar_model:ar_model_id (
                    id,
                    file_url,
                    updated_at
                )
            """)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .not("ar_model_id", operator: .is, value: "null")
        
        let response: [SpotWithModel] = try await query.execute().value
        print("✅ ARモデル付きスポット取得: \(response.count)件")
        return response
    }
    
    /// 特定のARモデルが他のスポットで使用されているかチェック
    /// - Parameter modelId: ARモデルID
    /// - Returns: 使用中の場合 true
    /// - Throws: データベースエラー
    func isARModelInUse(modelId: UUID) async throws -> Bool {
        let response = try await client
            .from("spots")
            .select("id", head: true, count: .exact)
            .eq("ar_model_id", value: modelId)
            .eq("is_active", value: true)
            .is("deleted_at", value: nil)
            .limit(1)
            .execute()
        
        return (response.count ?? 0) > 0
    }
    
    // MARK: - Utility（ユーティリティ）
    
    /// 2点間の距離を計算（ハバーサイン公式）
    /// - Returns: 距離（キロメートル）
    private func calculateDistance(
        lat1: Double,
        lon1: Double,
        lat2: Double,
        lon2: Double
    ) -> Double {
        let earthRadius = 6371.0
        
        let dLat = (lat2 - lat1) * .pi / 180.0
        let dLon = (lon2 - lon1) * .pi / 180.0
        
        let a = sin(dLat / 2) * sin(dLat / 2) +
                cos(lat1 * .pi / 180.0) * cos(lat2 * .pi / 180.0) *
                sin(dLon / 2) * sin(dLon / 2)
        
        let c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
}

// MARK: - Supporting Types

/// イベントスポットとスポット情報の結合データ（内部使用）
private struct EventSpotWithSpot: Codable {
    let spots: Spot
}

/// チェックイン履歴のモデル
struct SpotVisit: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let spotId: UUID
    let eventId: UUID?
    let latitude: Double?
    let longitude: Double?
    let visitedAt: Date
    let spotNameSnapshot: String?
    let eventNameSnapshot: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case spotId = "spot_id"
        case eventId = "event_id"
        case latitude
        case longitude
        case visitedAt = "visited_at"
        case spotNameSnapshot = "spot_name_snapshot"
        case eventNameSnapshot = "event_name_snapshot"
    }
}

/// イベント進捗情報
struct EventProgress {
    let eventId: UUID
    let totalSpots: Int
    let visitedSpots: Int
    let completionPercentage: Double
    
    var isCompleted: Bool {
        return visitedSpots >= totalSpots && totalSpots > 0
    }
}

/// リポジトリのエラー型
enum RepositoryError: LocalizedError {
    case notAuthenticated(message: String)
    case unsupportedFileFormat(format: String, message: String)
    case notFound(message: String)
    case invalidData(message: String)
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated(let message),
             .unsupportedFileFormat(_, let message),
             .notFound(let message),
             .invalidData(let message):
            return message
        }
    }
}

// MARK: - Debug Extension

#if DEBUG
extension DataRepository {
    /// テスト用：接続確認
    func testConnection() async -> Bool {
        do {
            let _: [Spot] = try await client
                .from("spots")
                .select("*")
                .limit(1)
                .execute()
                .value
            print("✅ Supabase接続成功")
            return true
        } catch {
            print("❌ Supabase接続失敗: \(error)")
            return false
        }
    }
}
#endif
