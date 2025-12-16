//
//  AcquiredStamp.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/15.
//

import Foundation

/// 取得済みスタンプの情報
/// DBの spot_visit テーブルに対応
struct AcquiredStamp: Identifiable, Codable {
    // MARK: - DB Properties
    
    let id: UUID
    let userId: UUID
    let spotId: UUID
    let eventId: UUID?
    let latitude: Double?
    let longitude: Double?
    let visitedAt: Date
    let spotNameSnapshot: String?
    let eventNameSnapshot: String?
    
    // MARK: - Computed Properties (安全な変換のみ)
    
    /// 画像ファイル名（ローカル保存用）
    /// ✅ 安全: 単純な文字列生成
    var imageFileName: String {
        return "stamp_\(id.uuidString).png"
    }
    
    /// スポット名を取得（スナップショットまたはデフォルト）
    var displaySpotName: String {
        return spotNameSnapshot ?? "不明なスポット"
    }
    
    /// イベント名を取得（参加していれば）
    var displayEventName: String? {
        return eventNameSnapshot
    }
    
    /// 位置情報があるかチェック
    var hasLocation: Bool {
        return latitude != nil && longitude != nil
    }
    
    /// 日付の表示用文字列
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: visitedAt)
    }
    
    // MARK: - Display Helpers (安全な表示用ヘルパー)
    
    /// 表示用のスポットID文字列
    /// ✅ 安全: 読み取り専用
    var displaySpotId: String {
        spotId.uuidString
    }
    
    /// 表示用の取得日時（旧コードとの互換性）
    /// ✅ 安全: 単なるエイリアス
    var acquiredDate: Date {
        return visitedAt
    }
    
    // MARK: - Codable Keys
    
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

// MARK: - Debug Extension

#if DEBUG
extension AcquiredStamp {
    static let testStamp = AcquiredStamp(
        id: UUID(),
        userId: UUID(),
        spotId: UUID(),
        eventId: nil,
        latitude: 34.6829,
        longitude: 135.1862,
        visitedAt: Date(),
        spotNameSnapshot: "神戸ポートタワー",
        eventNameSnapshot: nil
    )
    
    static let testStamps: [AcquiredStamp] = [
        testStamp,
        AcquiredStamp(
            id: UUID(),
            userId: UUID(),
            spotId: UUID(),
            eventId: UUID(),
            latitude: 34.6825,
            longitude: 135.1870,
            visitedAt: Date().addingTimeInterval(-86400),
            spotNameSnapshot: "メリケンパーク",
            eventNameSnapshot: "神戸港スタンプラリー"
        ),
        AcquiredStamp(
            id: UUID(),
            userId: UUID(),
            spotId: UUID(),
            eventId: nil,
            latitude: nil,
            longitude: nil,
            visitedAt: Date().addingTimeInterval(-172800),
            spotNameSnapshot: "南京町",
            eventNameSnapshot: nil
        )
    ]
}
#endif
