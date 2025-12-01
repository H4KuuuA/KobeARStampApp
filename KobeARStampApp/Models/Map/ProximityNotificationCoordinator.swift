//
//  ProximityNotificationCoordinator.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/14.
//

import Foundation
import _LocationEssentials

/// リージョン監視と通知送信を連携させるコーディネーター
final class ProximityNotificationCoordinator: ObservableObject {
    
    // MARK: - Properties
    
    private let regionMonitor: BackgroundRegionMonitor
    private let notificationService: NotificationService
    
    // MARK: - Initialization
    
    init(spots: [Spot], notificationService: NotificationService = .shared) {
        self.regionMonitor = BackgroundRegionMonitor(spots: spots)
        self.notificationService = notificationService
        
        // デリゲートを設定
        regionMonitor.delegate = self
        
        // 通知権限をリクエスト
        notificationService.requestPermission { granted in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("⚠️ Notification permission denied")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// スタンプを獲得したときに呼び出す
    func onStampCollected(spotId: String) {
        // リージョン監視側: 再検知を防ぐ
        regionMonitor.markAsDetected(spotId: spotId)
        
        // 通知サービス側: 今後の通知を停止
        notificationService.markAsCompleted(spotId: spotId)
        
        print("🎯 Stamp collected: \(spotId)")
    }
    
    /// スポットリストを更新
    func updateSpots(_ newSpots: [Spot]) {
        regionMonitor.updateSpots(newSpots)
    }
    
    /// すべてをリセット（テスト用）
    func resetAll() {
        regionMonitor.resetAllDetections()
        notificationService.resetAllNotificationHistory()
        notificationService.resetAllCompletions()
        print("🔄 All states reset")
    }
    
    /// 特定のスポットをリセット（再検知・再通知可能にする）
    func resetSpot(spotId: String) {
        regionMonitor.resetDetection(spotId: spotId)
        notificationService.resetNotificationHistory(spotId: spotId)
        notificationService.resetCompletion(spotId: spotId)
        print("🔄 Spot reset: \(spotId)")
    }
    
    /// パラメータをカスタマイズ
    func configure(
        regionRadius: Double? = nil,
        detectionThreshold: Double? = nil,
        accuracyFactor: Double? = nil,
        detectionCooldown: TimeInterval? = nil,
        notificationCooldown: TimeInterval? = nil
    ) {
        if let regionRadius = regionRadius {
            regionMonitor.regionRadius = regionRadius
        }
        if let detectionThreshold = detectionThreshold {
            regionMonitor.detectionThreshold = detectionThreshold
        }
        if let accuracyFactor = accuracyFactor {
            regionMonitor.accuracyFactor = accuracyFactor
        }
        if let detectionCooldown = detectionCooldown {
            regionMonitor.detectionCooldown = detectionCooldown
        }
        if let notificationCooldown = notificationCooldown {
            notificationService.notificationCooldown = notificationCooldown
        }
        
        print("⚙️ Configuration updated")
    }
}

// MARK: - BackgroundRegionMonitorDelegate

extension ProximityNotificationCoordinator: BackgroundRegionMonitorDelegate {
    
    func regionMonitor(
        _ monitor: BackgroundRegionMonitor,
        didEnterProximityOf spot: Spot,
        distance: CLLocationDistance,
        accuracy: CLLocationDistance
    ) {
        print("📍 Proximity detected: \(spot.name) - sending notification")
        
        // 通知を送信
        notificationService.sendArrivalNotification(
            for: spot,
            distance: distance,
            accuracy: accuracy
        )
    }
}
