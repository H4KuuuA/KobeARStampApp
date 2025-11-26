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
    @StateObject private var stampManager = StampManager()
    @StateObject private var proximityNotification: ProximityNotificationCoordinator
    
    init() {
        let manager = StampManager()
        _stampManager = StateObject(wrappedValue: manager)
        _proximityNotification = StateObject(wrappedValue: ProximityNotificationCoordinator(spots: manager.allSpots))
    }
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(proximityNotification)
                .environmentObject(stampManager)
        }
    }
}
