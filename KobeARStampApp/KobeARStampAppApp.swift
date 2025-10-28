//
//  KobeARStampAppApp.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/27.
//

import SwiftUI

@main
struct KobeARStampAppApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var proximityNotification = ProximityNotificationCoordinator(pins: mockPins)
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(proximityNotification) // ⬅️ この行を追加
        }
    }
}
