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
    
    init(pins: [CustomPin], notificationService: NotificationService = .shared) {
        self.regionMonitor = BackgroundRegionMonitor(pins: pins)
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
    func onStampCollected(pinId: UUID) {
        // リージョン監視側: 再検知を防ぐ
        regionMonitor.markAsDetected(pinId: pinId)
        
        // 通知サービス側: 今後の通知を停止
        notificationService.markAsCompleted(pinId: pinId)
        
        print("🎯 Stamp collected: \(pinId)")
    }
    
    /// ピンリストを更新
    func updatePins(_ newPins: [CustomPin]) {
        regionMonitor.updatePins(newPins)
    }
    
    /// すべてをリセット（テスト用）
    func resetAll() {
        regionMonitor.resetAllDetections()
        notificationService.resetAllNotificationHistory()
        notificationService.resetAllCompletions()
        print("🔄 All states reset")
    }
    
    /// 特定のピンをリセット（再検知・再通知可能にする）
    func resetPin(pinId: UUID) {
        regionMonitor.resetDetection(pinId: pinId)
        notificationService.resetNotificationHistory(pinId: pinId)
        notificationService.resetCompletion(pinId: pinId)
        print("🔄 Pin reset: \(pinId)")
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
        didEnterProximityOf pin: CustomPin,
        distance: CLLocationDistance,
        accuracy: CLLocationDistance
    ) {
        print("📍 Proximity detected: \(pin.title) - sending notification")
        
        // 通知を送信
        notificationService.sendArrivalNotification(
            for: pin,
            distance: distance,
            accuracy: accuracy
        )
    }
}
