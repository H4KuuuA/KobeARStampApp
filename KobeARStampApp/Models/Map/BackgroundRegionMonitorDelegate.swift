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
    /// スポットの25m圏内に侵入したときに呼ばれる
    func regionMonitor(_ monitor: BackgroundRegionMonitor, didEnterProximityOf spot: Spot, distance: CLLocationDistance, accuracy: CLLocationDistance)
}

/// バックグラウンドでリージョン監視を行うクラス（距離判定のみ）
final class BackgroundRegionMonitor: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private var spots: [Spot]
    
    weak var delegate: BackgroundRegionMonitorDelegate?
    
    // 最後に侵入を検知した時刻（チャタリング防止用）
    private var lastDetectionTimes: [String: Date] = [:]
    
    // 検知済みスポット（再検知を防ぐ）
    private var detectedSpotIds: Set<String> = []
    
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
    
    init(locationManager: CLLocationManager = CLLocationManager(), spots: [Spot]) {
        self.locationManager = locationManager
        self.spots = spots
        
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
        
        // 各スポットに対してリージョンを設定
        for spot in spots {
            let coordinate = spot.coordinate
            
            let region = CLCircularRegion(
                center: coordinate,
                radius: regionRadius,
                identifier: spot.id
            )
            
            region.notifyOnEntry = true
            region.notifyOnExit = false
            
            locationManager.startMonitoring(for: region)
            
            print("📍 Monitoring region for: \(spot.name) (radius: \(regionRadius)m)")
        }
        
        print("✅ BackgroundRegionMonitor: Setup complete for \(spots.count) spots")
    }
    
    // MARK: - Detection Logic
    
    /// 距離判定を実行
    private func performDistanceCheck(at location: CLLocation) {
        for spot in spots {
            // 検知済みスポットはスキップ
            if detectedSpotIds.contains(spot.id) {
                continue
            }
            
            // クールダウンチェック
            if let lastTime = lastDetectionTimes[spot.id],
               Date().timeIntervalSince(lastTime) < detectionCooldown {
                continue
            }
            
            let coordinate = spot.coordinate
            
            let spotLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            let distance = location.distance(from: spotLocation)
            let accuracy = max(location.horizontalAccuracy, 0)
            let effectiveThreshold = max(detectionThreshold, accuracy * accuracyFactor)
            
            print("📏 \(spot.name): distance=\(String(format: "%.1f", distance))m, threshold=\(String(format: "%.1f", effectiveThreshold))m, accuracy=\(String(format: "%.1f", accuracy))m")
            
            if distance <= effectiveThreshold {
                print("✅ Detection confirmed for: \(spot.name)")
                
                // 最終検知時刻を記録
                lastDetectionTimes[spot.id] = Date()
                
                // デリゲートに通知
                delegate?.regionMonitor(self, didEnterProximityOf: spot, distance: distance, accuracy: accuracy)
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// スポットを検知済みとしてマーク（再検知を防ぐ）
    func markAsDetected(spotId: String) {
        detectedSpotIds.insert(spotId)
        print("✅ Spot marked as detected: \(spotId)")
    }
    
    /// スポットの検知済み状態をリセット（再検知可能にする）
    func resetDetection(spotId: String) {
        detectedSpotIds.remove(spotId)
        lastDetectionTimes.removeValue(forKey: spotId)
        print("🔄 Detection reset for spot: \(spotId)")
    }
    
    /// すべての検知状態をリセット
    func resetAllDetections() {
        detectedSpotIds.removeAll()
        lastDetectionTimes.removeAll()
        print("🔄 All detections reset")
    }
    
    /// スポットリストを更新
    func updateSpots(_ newSpots: [Spot]) {
        self.spots = newSpots
        setupRegionMonitoring()
    }
}

// MARK: - CLLocationManagerDelegate

extension BackgroundRegionMonitor: CLLocationManagerDelegate {
    
    /// リージョン侵入検知
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let spot = spots.first(where: { $0.id == region.identifier }) else { return }
        
        print("🔔 Entered region (100m) for: \(spot.name)")
        
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
