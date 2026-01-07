//
//  EventBannerManager.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2026/01/06.
//

import SwiftUI

/// イベントバナーの表示管理およびイベント情報管理を行うクラス
@MainActor
class EventBannerManager: ObservableObject {
    static let shared = EventBannerManager()
    
    // バナー表示管理
    @Published var shouldShowBanner = false
    
    // イベント情報管理
    @Published var currentEvent: Event?
    @Published var allEvents: [Event] = []
    @Published var isLoading = false
    
    private let userDefaults = UserDefaults.standard
    private let lastShownDateKey = "eventBannerLastShownDate"
    
    private init() {}
    
    // MARK: - イベント取得機能
    
    /// 現在開催中のイベントを取得（StampManagerから取得）
    func fetchCurrentEvent() async {
        isLoading = true
        defer { isLoading = false }
        
        // StampManagerから現在のイベントを取得
        await StampManager.shared.fetchCurrentEvent()
        
        // StampManagerのcurrentEventを参照
        self.currentEvent = StampManager.shared.currentEvent
        
        print("✅ EventBannerManager: currentEvent = \(currentEvent?.name ?? "nil")")
    }
    
    /// イベントが現在開催中かどうかを判定
    func isEventActive(_ event: Event) -> Bool {
        guard let startTime = event.startTime,
              let endTime = event.endTime else {
            return false
        }
        let now = Date()
        return event.status == true &&
               startTime <= now &&
               endTime >= now
    }
    
    // MARK: - バナー表示管理機能
    
    /// アプリ起動時にバナーを表示すべきかチェック
    func checkAndShowBanner(event: Event?) {
        print("🎯 checkAndShowBanner called")
        print("🎯 Event: \(event?.name ?? "nil")")
        
        guard let event = event else {
            print("❌ No event provided")
            shouldShowBanner = false
            return
        }
        
        print("🎯 Event details - isOngoing: \(event.isOngoing), isPublic: \(event.isPublic), status: \(event.status)")
        print("🎯 Event period: \(event.displayPeriod)")
        
        // イベントが開催中かつ公開されているか確認
        guard event.isOngoing && event.isPublic && event.status else {
            print("❌ Event conditions not met")
            shouldShowBanner = false
            return
        }
        
        // 最後に表示した日付を取得
        if let lastShownDate = userDefaults.object(forKey: lastShownDateKey) as? Date {
            print("🎯 Last shown date: \(lastShownDate)")
            // 同じ日かどうかをチェック
            if Calendar.current.isDateInToday(lastShownDate) {
                print("❌ Already shown today")
                // 今日既に表示済み
                shouldShowBanner = false
                return
            }
        } else {
            print("🎯 No previous show history")
        }
        
        // バナーを表示
        print("✅ Showing banner for event: \(event.name)")
        currentEvent = event
        shouldShowBanner = true
        
        // 表示日時を記録
        userDefaults.set(Date(), forKey: lastShownDateKey)
    }
    
    /// StampManagerから現在のイベントを取得してバナーをチェック
    func checkAndShowBannerFromStampManager() {
        let stampManager = StampManager.shared
        
        print("🎯 checkAndShowBannerFromStampManager called")
        print("🎯 StampManager currentEvent: \(stampManager.currentEvent?.name ?? "nil")")
        
        // DBから取得したイベントを使用（デバッグ・本番共通）
        if let currentEvent = stampManager.currentEvent {
            print("🎯 Using DB event: \(currentEvent.name)")
            checkAndShowBanner(event: currentEvent)
        } else {
            #if DEBUG
            // デバッグ時のみ、DBにイベントがない場合はテストイベントで表示
            print("⚠️ No DB event found, using test event for debugging")
            checkAndShowBanner(event: Event.testEvent)
            #else
            print("❌ No event available")
            shouldShowBanner = false
            #endif
        }
    }
    
    /// バナーを閉じる
    func dismissBanner() {
        withAnimation {
            shouldShowBanner = false
        }
        
        // 少し遅延してからイベントをクリア（バナー表示用のイベント情報のみクリア）
        // 注意: currentEventは他の画面でも参照されるため、バナー終了後もnilにしない
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // バナー表示状態のみリセット
        }
    }
    
    /// テスト用：表示履歴をリセット
    func resetShowHistory() {
        userDefaults.removeObject(forKey: lastShownDateKey)
    }
}
