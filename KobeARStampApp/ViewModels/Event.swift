//
//  Event.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/16.
//

import SwiftUI

/// イベント情報（DB連携版）
/// DBの events テーブルに完全対応
struct Event: Identifiable, Codable, Equatable, Hashable {
    // MARK: - DB Properties (events テーブルの全カラム)
    
    let id: UUID
    let name: String
    let description: String?
    let organizer: String?
    let imageUrl: String?        // image_url
    let startTime: Date?         // start_time
    let endTime: Date?           // end_time
    let status: Bool             // default: true
    let isPublic: Bool           // is_public (デフォルト: true)
    let createdByUser: UUID?     // created_by_user
    let createdAt: Date          // created_at
    let updatedAt: Date?         // updated_at
    
    // MARK: - Computed Properties (ローカル専用)
    
    /// 画像URL（URL型）
    var imageURL: URL? {
        guard let imageUrl = imageUrl else { return nil }
        return URL(string: imageUrl)
    }
    
    /// プレースホルダー画像名（ローカルアセット用）
    var placeholderImageName: String {
        return "event_placeholder_default"
    }
    
    /// 表示用のID文字列（デバッグ・表示用）
    var displayId: String {
        id.uuidString
    }
    
    /// 短縮ID（デバッグ用）
    var shortId: String {
        String(id.uuidString.prefix(8))
    }
    
    /// イベントが開催中かどうか
    var isOngoing: Bool {
        guard let start = startTime, let end = endTime else { return false }
        let now = Date()
        return now >= start && now <= end
    }
    
    /// イベントが終了しているかどうか
    var isFinished: Bool {
        guard let end = endTime else { return false }
        return Date() > end
    }
    
    /// イベントが開催予定かどうか
    var isUpcoming: Bool {
        guard let start = startTime else { return false }
        return Date() < start
    }
    
    /// イベント期間の表示用文字列
    var displayPeriod: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        
        if let start = startTime, let end = endTime {
            return "\(formatter.string(from: start)) 〜 \(formatter.string(from: end))"
        } else if let start = startTime {
            return "\(formatter.string(from: start)) 〜"
        } else if let end = endTime {
            return "〜 \(formatter.string(from: end))"
        } else {
            return "期間未定"
        }
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case organizer
        case imageUrl = "image_url"
        case startTime = "start_time"
        case endTime = "end_time"
        case status
        case isPublic = "is_public"
        case createdByUser = "created_by_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Equatable & Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Debug Extension

#if DEBUG
extension Event {
    /// テスト用のサンプルイベント
    static let testEvent = Event(
        id: UUID(),
        name: "神戸開港150周年記念スタンプラリー",
        description: "神戸の歴史的スポットを巡るスタンプラリーです",
        organizer: "神戸市観光局",
        imageUrl: "https://example.com/event.jpg",
        startTime: Date(),
        endTime: Calendar.current.date(byAdding: .day, value: 30, to: Date()),
        status: true,
        isPublic: true,
        createdByUser: nil,
        createdAt: Date(),
        updatedAt: nil
    )
    
    static let testEvents: [Event] = [
        testEvent,
        Event(
            id: UUID(),
            name: "港町ARツアー",
            description: "ARで楽しむ神戸港の歴史",
            organizer: "神戸AR協会",
            imageUrl: nil,
            startTime: Calendar.current.date(byAdding: .day, value: -10, to: Date()),
            endTime: Calendar.current.date(byAdding: .day, value: 20, to: Date()),
            status: true,
            isPublic: true,
            createdByUser: nil,
            createdAt: Date(),
            updatedAt: nil
        ),
        Event(
            id: UUID(),
            name: "南京町フードラリー",
            description: "中華街のグルメスポットを制覇しよう",
            organizer: "南京町商店街振興組合",
            imageUrl: nil,
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .day, value: 7, to: Date()),
            status: true,
            isPublic: true,
            createdByUser: nil,
            createdAt: Date(),
            updatedAt: nil
        )
    ]
}
#endif
