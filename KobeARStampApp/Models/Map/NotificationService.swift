//
//  NotificationService.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/14.
//

import Foundation
import UserNotifications
import _LocationEssentials

/// ローカル通知を管理するサービスクラス
final class NotificationService {
    
    // MARK: - Singleton
    
    static let shared = NotificationService()
    
    private init() {}
    
    // MARK: - Properties
    
    // 通知送信履歴（重複防止用）
    private var notificationHistory: [String: Date] = [:]
    
    // スタンプ獲得済みスポット（通知不要）
    private var completedSpotIds: Set<String> = []
    
    // MARK: - 調整可能パラメータ
    
    /// 同じスポットへの再通知間隔（秒）
    var notificationCooldown: TimeInterval = 1800.0 // 30分
    
    // MARK: - Public Methods
    
    /// 通知権限をリクエスト
    func requestPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            if let error = error {
                print("❌ Notification permission error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    /// スポット到着通知を送信
    func sendArrivalNotification(
        for spot: Spot,
        distance: CLLocationDistance,
        accuracy: CLLocationDistance
    ) {
        // スタンプ獲得済みチェック
        if completedSpotIds.contains(spot.id) {
            print("🔕 Notification suppressed (stamp collected): \(spot.name)")
            return
        }
        
        // クールダウンチェック
        if let lastTime = notificationHistory[spot.id],
           Date().timeIntervalSince(lastTime) < notificationCooldown {
            let elapsed = Date().timeIntervalSince(lastTime)
            print("🔕 Notification suppressed (cooldown: \(Int(elapsed))s): \(spot.name)")
            return
        }
        
        // 通知内容の作成
        let content = UNMutableNotificationContent()
        content.title = "📍 スポット到着！"
        content.body = "\(spot.name)に到着しました。アプリを開いてスタンプをゲットしよう！"
        content.sound = .default
        
        // カテゴリとユーザー情報
        content.categoryIdentifier = "SPOT_ARRIVAL"
        content.userInfo = [
            "spotId": spot.id,
            "spotName": spot.name,
            "latitude": spot.coordinate.latitude,
            "longitude": spot.coordinate.longitude,
            "distance": distance,
            "accuracy": accuracy
        ]
        
        // バッジ
        content.badge = NSNumber(value: getUnreadNotificationCount() + 1)
        
        // 通知リクエスト
        let identifier = "spot_\(spot.id)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // 即座に送信
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent: \(spot.name) (distance: \(String(format: "%.1f", distance))m)")
                
                // 履歴を記録
                DispatchQueue.main.async {
                    self.notificationHistory[spot.id] = Date()
                }
            }
        }
    }
    
    /// スタンプ獲得済みとしてマーク
    func markAsCompleted(spotId: String) {
        completedSpotIds.insert(spotId)
        print("✅ Spot marked as completed (no more notifications): \(spotId)")
    }
    
    /// スタンプ獲得状態をリセット
    func resetCompletion(spotId: String) {
        completedSpotIds.remove(spotId)
        print("🔄 Spot completion reset: \(spotId)")
    }
    
    /// 通知履歴をリセット（再通知可能にする）
    func resetNotificationHistory(spotId: String) {
        notificationHistory.removeValue(forKey: spotId)
        print("🔄 Notification history reset: \(spotId)")
    }
    
    /// すべての通知履歴をリセット
    func resetAllNotificationHistory() {
        notificationHistory.removeAll()
        print("🔄 All notification history reset")
    }
    
    /// すべての完了状態をリセット
    func resetAllCompletions() {
        completedSpotIds.removeAll()
        print("🔄 All completions reset")
    }
    
    /// バッジをクリア
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    /// 配信済み通知をすべて削除
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        print("🗑️ All delivered notifications cleared")
    }
    
    // MARK: - Private Methods
    
    /// 未読通知数を取得
    private func getUnreadNotificationCount() -> Int {
        var count = 0
        let semaphore = DispatchSemaphore(value: 0)
        
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            count = notifications.count
            semaphore.signal()
        }
        
        semaphore.wait()
        return count
    }
}

// MARK: - Convenience Methods

extension NotificationService {
    
    /// テスト用の通知を即座に送信
    func sendTestNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "test_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Test notification failed: \(error.localizedDescription)")
            } else {
                print("✅ Test notification sent")
            }
        }
    }
}
