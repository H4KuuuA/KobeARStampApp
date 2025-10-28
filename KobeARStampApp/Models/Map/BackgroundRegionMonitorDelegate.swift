//
//  BackgroundRegionMonitorDelegate.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/14.
//

import Foundation
import CoreLocation

/// リージョン監視の結果を通知するデリゲート
protocol BackgroundRegionMonitorDelegate: AnyObject {
    /// ピンの25m圏内に侵入したときに呼ばれる
    func regionMonitor(_ monitor: BackgroundRegionMonitor, didEnterProximityOf pin: CustomPin, distance: CLLocationDistance, accuracy: CLLocationDistance)
}

/// バックグラウンドでリージョン監視を行うクラス（距離判定のみ）
final class BackgroundRegionMonitor: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private var pins: [CustomPin]
    
    weak var delegate: BackgroundRegionMonitorDelegate?
    
    // 最後に侵入を検知した時刻（チャタリング防止用）
    private var lastDetectionTimes: [UUID: Date] = [:]
    
    // 検知済みピン（再検知を防ぐ）
    private var detectedPinIds: Set<UUID> = []
    
    // MARK: - 調整可能パラメータ
    
    /// リージョン監視の半径（メートル）
    /// - iOS推奨値: 100m以上（安定性のため）
    var regionRadius: CLLocationDistance = 100.0
    
    /// 侵入判定の実際のしきい値（メートル）
    var detectionThreshold: CLLocationDistance = 25.0
    
    /// 距離判定の精度補正係数
    var accuracyFactor: Double = 1.5
    
    /// 短期クールダウン（チャタリング防止）
    var detectionCooldown: TimeInterval = 300.0 // 5分
    
    // MARK: - Initialization
    
    init(locationManager: CLLocationManager = CLLocationManager(), pins: [CustomPin]) {
        self.locationManager = locationManager
        self.pins = pins
        
        super.init()
        
        self.locationManager.delegate = self
        
        setupRegionMonitoring()
    }
    
    // MARK: - Setup
    
    /// リージョン監視のセットアップ
    private func setupRegionMonitoring() {
        let status = locationManager.authorizationStatus
        
        guard status == .authorizedAlways || status == .authorizedWhenInUse else {
            print("⚠️ BackgroundRegionMonitor: Location permission not granted")
            return
        }
        
        // 既存のリージョンをクリア
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // 各ピンに対してリージョンを設定
        for pin in pins {
            let region = CLCircularRegion(
                center: pin.coordinate,
                radius: regionRadius,
                identifier: pin.id.uuidString
            )
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            
            print("📍 Monitoring region for: \(pin.title) (radius: \(regionRadius)m)")
        }
        
        print("✅ BackgroundRegionMonitor: Setup complete for \(pins.count) pins")
    }
    
    // MARK: - Detection Logic
    
    /// 距離判定を実行
    private func performDistanceCheck(at location: CLLocation) {
        for pin in pins {
            // 検知済みピンはスキップ
            if detectedPinIds.contains(pin.id) {
                continue
            }
            
            // クールダウンチェック
            if let lastTime = lastDetectionTimes[pin.id],
               Date().timeIntervalSince(lastTime) < detectionCooldown {
                continue
            }
            
            let pinLocation = CLLocation(
                latitude: pin.coordinate.latitude,
                longitude: pin.coordinate.longitude
            )
            
            let distance = location.distance(from: pinLocation)
            let accuracy = max(location.horizontalAccuracy, 0)
            let effectiveThreshold = max(detectionThreshold, accuracy * accuracyFactor)
            
            print("📏 \(pin.title): distance=\(String(format: "%.1f", distance))m, threshold=\(String(format: "%.1f", effectiveThreshold))m, accuracy=\(String(format: "%.1f", accuracy))m")
            
            if distance <= effectiveThreshold {
                print("✅ Detection confirmed for: \(pin.title)")
                
                // 最終検知時刻を記録
                lastDetectionTimes[pin.id] = Date()
                
                // デリゲートに通知
                delegate?.regionMonitor(self, didEnterProximityOf: pin, distance: distance, accuracy: accuracy)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// ピンを検知済みとしてマーク（再検知を防ぐ）
    func markAsDetected(pinId: UUID) {
        detectedPinIds.insert(pinId)
        print("✅ Pin marked as detected: \(pinId)")
    }
    
    /// ピンの検知済み状態をリセット（再検知可能にする）
    func resetDetection(pinId: UUID) {
        detectedPinIds.remove(pinId)
        lastDetectionTimes.removeValue(forKey: pinId)
        print("🔄 Detection reset for pin: \(pinId)")
    }
    
    /// すべての検知状態をリセット
    func resetAllDetections() {
        detectedPinIds.removeAll()
        lastDetectionTimes.removeAll()
        print("🔄 All detections reset")
    }
    
    /// ピンリストを更新
    func updatePins(_ newPins: [CustomPin]) {
        self.pins = newPins
        setupRegionMonitoring()
    }
}

// MARK: - CLLocationManagerDelegate

extension BackgroundRegionMonitor: CLLocationManagerDelegate {
    
    /// リージョン侵入検知
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let pinId = UUID(uuidString: region.identifier) else { return }
        guard let pin = pins.first(where: { $0.id == pinId }) else { return }
        
        print("🔔 Entered region (100m) for: \(pin.title)")
        
        // 精密な距離判定を実行
        manager.requestLocation()
    }
    
    /// 位置情報更新（精密判定用）
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let currentLocation = locations.last else { return }
        
        print("📍 Location updated - accuracy: \(String(format: "%.1f", currentLocation.horizontalAccuracy))m")
        
        performDistanceCheck(at: currentLocation)
    }
    
    /// 位置情報取得失敗
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        print("❌ Location update failed: \(error.localizedDescription)")
    }
    
    /// リージョン監視開始
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("✅ Monitoring started: \(region.identifier)")
        manager.requestState(for: region)
    }
    
    /// リージョン状態確認
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        if state == .inside {
            print("ℹ️ Already inside region: \(region.identifier)")
            manager.requestLocation()
        }
    }
    
    /// リージョン監視エラー
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("❌ Region monitoring failed: \(error.localizedDescription)")
    }
}
