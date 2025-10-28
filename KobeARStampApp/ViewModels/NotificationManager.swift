//
//  NotificationManager.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/20.
//

import Foundation
import Combine

/// アプリ内通知を管理するクラス
class NotificationManager: ObservableObject, @unchecked Sendable {
    // MARK: - Singleton
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    /// 通知のリスト（新しい順）
    @Published private(set) var notifications: [NotificationItem] = []
    
    /// 新着通知があるかどうか
    @Published private(set) var hasUnviewedNotifications: Bool = false
    
    // MARK: - Private Properties
    
    /// 保存するファイル名
    private let fileName = "notifications.json"
    
    /// 最終閲覧時刻の保存キー
    private let lastViewedDateKey = "lastViewedNotificationDate"
    
    /// 保存する最大通知数
    private let maxNotifications = 100
    
    /// 最終閲覧時刻
    private var lastViewedDate: Date? {
        get {
            UserDefaults.standard.object(forKey: lastViewedDateKey) as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: lastViewedDateKey)
            updateUnviewedStatus()
        }
    }
    
    /// データ保存用のURL
    private var fileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    // MARK: - Initialization
    
    private init() {
        loadNotifications()
    }
    
    // MARK: - Public Methods
    
    /// 通知を追加
    /// - Parameter notification: 追加する通知
    func addNotification(_ notification: NotificationItem) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 先頭に追加（新しい順）
            self.notifications.insert(notification, at: 0)
            
            // 最大数を超えたら古いものを削除
            if self.notifications.count > self.maxNotifications {
                self.notifications = Array(self.notifications.prefix(self.maxNotifications))
            }
            
            self.saveNotifications()
            self.updateUnviewedStatus()
            
            print("📬 通知を追加: \(notification.title)")
        }
    }
    
    /// 複数の通知を一括追加
    /// - Parameter notifications: 追加する通知の配列
    func addNotifications(_ newNotifications: [NotificationItem]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            for notification in newNotifications {
                self.notifications.insert(notification, at: 0)
            }
            
            if self.notifications.count > self.maxNotifications {
                self.notifications = Array(self.notifications.prefix(self.maxNotifications))
            }
            
            self.saveNotifications()
            self.updateUnviewedStatus()
        }
    }
    
    /// 通知を削除
    /// - Parameter id: 削除する通知のID
    func removeNotification(id: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notifications.removeAll { $0.id == id }
            self.saveNotifications()
            self.updateUnviewedStatus()
            
            print("🗑️ 通知を削除: ID \(id)")
        }
    }
    
    /// 複数の通知を削除
    /// - Parameter ids: 削除する通知のID配列
    func removeNotifications(ids: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notifications.removeAll { ids.contains($0.id) }
            self.saveNotifications()
            self.updateUnviewedStatus()
        }
    }
    
    /// 全ての通知を削除
    func removeAllNotifications() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.notifications.removeAll()
            self.saveNotifications()
            self.updateUnviewedStatus()
            
            print("🗑️ 全ての通知を削除")
        }
    }
    
    /// 特定のタイプの通知を取得
    /// - Parameter type: 通知タイプ
    /// - Returns: 該当する通知の配列
    func getNotifications(ofType type: NotificationType) -> [NotificationItem] {
        return notifications.filter { $0.type == type }
    }
    
    /// 特定のピンに関連する通知を取得
    /// - Parameter pinID: ピンのID
    /// - Returns: 該当する通知の配列
    func getNotifications(forPinID pinID: String) -> [NotificationItem] {
        return notifications.filter { $0.relatedPinID == pinID }
    }
    
    /// 日付範囲で通知を取得
    /// - Parameters:
    ///   - startDate: 開始日時
    ///   - endDate: 終了日時
    /// - Returns: 該当する通知の配列
    func getNotifications(from startDate: Date, to endDate: Date) -> [NotificationItem] {
        return notifications.filter { notification in
            notification.timestamp >= startDate && notification.timestamp <= endDate
        }
    }
    
    /// 今日の通知を取得
    /// - Returns: 今日の通知の配列
    func getTodaysNotifications() -> [NotificationItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return getNotifications(from: today, to: tomorrow)
    }
    
    // MARK: - Private Methods
    
    /// 通知をファイルに保存
    private func saveNotifications() {
        guard let fileURL = fileURL else {
            print("⚠️ 保存先URLの取得に失敗")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(notifications)
            try data.write(to: fileURL, options: .atomic)
            print("💾 通知を保存しました: \(notifications.count)件")
        } catch {
            print("⚠️ 通知の保存に失敗: \(error.localizedDescription)")
        }
    }
    
    /// 通知をファイルから読み込み
    private func loadNotifications() {
        guard let fileURL = fileURL else {
            print("⚠️ 読み込み元URLの取得に失敗")
            return
        }
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("ℹ️ 通知ファイルが存在しません（初回起動）")
            return
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            notifications = try decoder.decode([NotificationItem].self, from: data)
            updateUnviewedStatus()
            print("📂 通知を読み込みました: \(notifications.count)件")
        } catch {
            print("⚠️ 通知の読み込みに失敗: \(error.localizedDescription)")
            notifications = []
            updateUnviewedStatus()
        }
    }
    
    /// 未読状態を更新
    private func updateUnviewedStatus() {
        // 未読の判定: 最終閲覧日時より新しい通知がある場合に true
        if notifications.isEmpty {
            hasUnviewedNotifications = false
            return
        }
        if let last = lastViewedDate {
            hasUnviewedNotifications = notifications.contains { $0.timestamp > last }
        } else {
            // 最終閲覧日時が未設定の場合、通知が1件でもあれば未読とみなす
            hasUnviewedNotifications = !notifications.isEmpty
        }
    }

    /// すべての通知を既読にする（最終閲覧日時を現在時刻に更新）
    func markAllAsViewed() {
        lastViewedDate = Date()
    }
    
    /// 通知が新着かどうかを判定
    func isNew(_ notification: NotificationItem) -> Bool {
        guard let lastViewedDate = lastViewedDate else {
            // 最終閲覧日時が未設定なら全て新着扱い
            return true
        }
        return notification.timestamp > lastViewedDate
    }
    
    // MARK: - Debug Methods
    
    /// デバッグ用: サンプル通知を追加
    func addSampleNotifications() {
        let samples = NotificationItem.samples
        addNotifications(samples)
        print("🧪 サンプル通知を追加しました")
    }
    
    /// デバッグ用: 通知情報を出力
    func printNotificationsSummary() {
        print("📊 通知サマリー:")
        print("  - 総数: \(notifications.count)")
        
        let typeCount = Dictionary(grouping: notifications, by: { $0.type })
            .mapValues { $0.count }
        print("  - タイプ別:")
        for (type, count) in typeCount {
            print("    - \(type.appName): \(count)件")
        }
    }
}
