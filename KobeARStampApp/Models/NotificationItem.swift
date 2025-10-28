//
//  NotificationItem.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/20.
//

import Foundation

/// アプリ内通知を表すデータモデル
struct NotificationItem: Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// 一意のID
    let id: String
    
    /// 通知のタイプ
    let type: NotificationType
    
    /// 通知のタイトル（既に完成した文字列）
    let title: String
    
    /// 通知のメッセージ本文（既に完成した文字列）
    let message: String
    
    /// 通知が作成された日時
    let timestamp: Date
    
    /// 関連するピンのID（オプション）- ピン関連の通知の場合
    let relatedPinID: String?
    
    /// 追加のメタデータ（オプション）- 将来の拡張用
    let metadata: [String: String]?
    
    // MARK: - Initialization
    
    init(
        id: String = UUID().uuidString,
        type: NotificationType,
        title: String,
        message: String,
        timestamp: Date = Date(),
        relatedPinID: String? = nil,
        metadata: [String: String]? = nil
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.relatedPinID = relatedPinID
        self.metadata = metadata
    }
    
    // MARK: - Computed Properties
    
    /// 表示用の時間表記（"今", "5分前", "1時間前" など）
    var timeAgoText: String {
        let now = Date()
        let interval = now.timeIntervalSince(timestamp)
        
        if interval < 60 {
            return "今"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)分前"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)時間前"
        } else if interval < 172800 {
            return "昨日"
        } else {
            let days = Int(interval / 86400)
            return "\(days)日前"
        }
    }
}

// MARK: - Sample Data (for Preview)
extension NotificationItem {
    static var sampleProximity: NotificationItem {
        NotificationItem(
            type: .pinProximity,
            title: "神戸ポートタワー",
            message: "スポットに到着しました！ARスタンプを獲得できます",
            relatedPinID: "pin_001"
        )
    }
    
    static var sampleAchievement: NotificationItem {
        NotificationItem(
            type: .achievement,
            title: "初回訪問達成！",
            message: "初めてのスポットを訪れました。おめでとうございます！",
            timestamp: Date().addingTimeInterval(-300)
        )
    }
    
    static var sampleSystem: NotificationItem {
        NotificationItem(
            type: .system,
            title: "アップデート情報",
            message: "新しい機能が追加されました。詳細を確認してください。",
            timestamp: Date().addingTimeInterval(-7200)
        )
    }
    
    static var samples: [NotificationItem] {
        return [sampleProximity, sampleAchievement, sampleSystem]
    }
}
