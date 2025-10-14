//
//  AppDelegate.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/10.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        // 通知センターのデリゲートを設定
        UNUserNotificationCenter.current().delegate = self
        
        return true
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    /// フォアグラウンドで通知が届いたときの処理
    /// - このメソッドがないと、アプリ起動中は通知が表示されない
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // iOS 14+: バナー、サウンド、バッジをすべて表示
        completionHandler([.banner, .sound, .badge])
        
        print("📬 Notification presented in foreground: \(notification.request.content.title)")
    }
    
    /// 通知をタップしたときの処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // ピン情報を取得
        if let pinIdString = userInfo["pinId"] as? String,
           let pinId = UUID(uuidString: pinIdString) {
            
            print("📍 User tapped notification for pin: \(pinId)")
            
            // ここでアプリ内の適切な画面に遷移
            // 例: 該当ピンの詳細画面を開く
            NotificationCenter.default.post(
                name: .openPinDetail,
                object: nil,
                userInfo: ["pinId": pinId]
            )
        }
        
        completionHandler()
    }
}
