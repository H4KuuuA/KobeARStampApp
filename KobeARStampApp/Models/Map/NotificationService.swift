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
    private var notificationHistory: [UUID: Date] = [:]
    
    // スタンプ獲得済みピン（通知不要）
    private var completedPinIds: Set<UUID> = []
    
    // MARK: - 調整可能パラメータ
    
    /// 同じピンへの再通知間隔（秒）
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
    
    /// ピン到着通知を送信
    func sendArrivalNotification(
        for pin: CustomPin,
        distance: CLLocationDistance,
        accuracy: CLLocationDistance
    ) {
        // スタンプ獲得済みチェック
        if completedPinIds.contains(pin.id) {
            print("🔕 Notification suppressed (stamp collected): \(pin.title)")
            return
        }
        
        // クールダウンチェック
        if let lastTime = notificationHistory[pin.id],
           Date().timeIntervalSince(lastTime) < notificationCooldown {
            let elapsed = Date().timeIntervalSince(lastTime)
            print("🔕 Notification suppressed (cooldown: \(Int(elapsed))s): \(pin.title)")
            return
        }
        
        // 通知内容の作成
        let content = UNMutableNotificationContent()
        content.title = "📍 スポット到着！"
        content.body = "\(pin.title)に到着しました。アプリを開いてスタンプをゲットしよう！"
        content.sound = .default
        
        // カテゴリとユーザー情報
        content.categoryIdentifier = "PIN_ARRIVAL"
        content.userInfo = [
            "pinId": pin.id.uuidString,
            "pinTitle": pin.title,
            "latitude": pin.coordinate.latitude,
            "longitude": pin.coordinate.longitude,
            "distance": distance,
            "accuracy": accuracy
        ]
        
        // バッジ
        content.badge = NSNumber(value: getUnreadNotificationCount() + 1)
        
        // 通知リクエスト
        let identifier = "pin_\(pin.id.uuidString)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil // 即座に送信
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error.localizedDescription)")
            } else {
                print("✅ Notification sent: \(pin.title) (distance: \(String(format: "%.1f", distance))m)")
                
                // 履歴を記録
                DispatchQueue.main.async {
                    self.notificationHistory[pin.id] = Date()
                }
            }
        }
    }
    
    /// スタンプ獲得済みとしてマーク
    func markAsCompleted(pinId: UUID) {
        completedPinIds.insert(pinId)
        print("✅ Pin marked as completed (no more notifications): \(pinId)")
    }
    
    /// スタンプ獲得状態をリセット
    func resetCompletion(pinId: UUID) {
        completedPinIds.remove(pinId)
        print("🔄 Pin completion reset: \(pinId)")
    }
    
    /// 通知履歴をリセット（再通知可能にする）
    func resetNotificationHistory(pinId: UUID) {
        notificationHistory.removeValue(forKey: pinId)
        print("🔄 Notification history reset: \(pinId)")
    }
    
    /// すべての通知履歴をリセット
    func resetAllNotificationHistory() {
        notificationHistory.removeAll()
        print("🔄 All notification history reset")
    }
    
    /// すべての完了状態をリセット
    func resetAllCompletions() {
        completedPinIds.removeAll()
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
