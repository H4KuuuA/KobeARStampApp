//
//  LocationAwareCaptureManager.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/11.
//

import SwiftUI
import CoreLocation
import Combine

/// AR撮影時の位置判定を管理するクラス（ProximityDetectorを活用）
class LocationAwareCaptureManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 現在最も近いスポット
    @Published var currentNearestSpot: Spot?
    
    /// 撮影可能範囲内かどうか
    @Published var isWithinCaptureRange: Bool = false
    
    /// スポットまでの距離（メートル）
    @Published var distanceToSpot: CLLocationDistance = 0
    
    // MARK: - Private Properties
    
    private let locationManager: LocationManager
    private let proximityDetector: ProximityDetector  // ← 既存のProximityDetectorを活用
    private var cancellables = Set<AnyCancellable>()
    
    /// 撮影可能範囲（メートル）
    private let captureRadius: CLLocationDistance
    
    // MARK: - Initialization
    
    init(
        locationManager: LocationManager = .shared,
        proximityDetector: ProximityDetector = ProximityDetector()
    ) {
        self.locationManager = locationManager
        self.proximityDetector = proximityDetector
        self.captureRadius = proximityDetector.entryRadius
        
        setupLocationObserver()
    }
    
    // MARK: - Setup
    
    /// 位置情報の変更を監視
    private func setupLocationObserver() {
        Publishers.CombineLatest(
            locationManager.$latitude,
            locationManager.$longitude
        )
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
        .sink { [weak self] lat, lon in
            guard let self = self else { return }
            print("📍 位置更新: \(lat), \(lon)")
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Spot Detection
    
    /// 現在地から最も近いスポットを更新（ProximityDetectorを使用）
    /// - Parameter spots: チェック対象のスポットリスト
    func updateNearestSpot(with spots: [Spot]) {
        let lat = locationManager.latitude
        let lon = locationManager.longitude
        
        // 位置情報が取得できていない場合
        guard lat != 0.0, lon != 0.0 else {
            currentNearestSpot = nil
            isWithinCaptureRange = false
            distanceToSpot = 0
            return
        }
        
        let currentLocation = CLLocation(latitude: lat, longitude: lon)
        
        // ProximityDetectorのSpot拡張を使用
        if let nearest = proximityDetector.findNearestSpot(
            from: currentLocation,
            in: spots,
            maxDistance: captureRadius
        ) {
            // 撮影可能範囲内に見つかった
            currentNearestSpot = nearest.spot
            distanceToSpot = nearest.distance
            isWithinCaptureRange = true
            
            #if DEBUG
            print("✅ 最寄り: \(nearest.spot.name) - \(String(format: "%.1fm", nearest.distance))")
            #endif
            
        } else {
            // 範囲外、または最も近いスポットでも遠すぎる
            let spotsWithDistance = proximityDetector.calculateDistances(
                from: currentLocation,
                to: spots
            )
            
            if let nearest = spotsWithDistance.min(by: { $0.distance < $1.distance }) {
                currentNearestSpot = nearest.spot
                distanceToSpot = nearest.distance
                isWithinCaptureRange = false
                
                #if DEBUG
                print("⚠️ 最寄り: \(nearest.spot.name) - \(String(format: "%.1fm", nearest.distance))")
                #endif
            } else {
                currentNearestSpot = nil
                isWithinCaptureRange = false
                distanceToSpot = 0
            }
        }
    }
    
    // MARK: - Validation
    
    /// 特定のスポットで撮影可能かどうかを判定
    /// ⚠️ UUID型のパラメータに変更
    /// - Parameter spotID: 撮影しようとしているスポットのID
    /// - Returns: (撮影可能か, メッセージ)
    func canCaptureStamp(for spotID: UUID) -> (canCapture: Bool, message: String) {
        // 撮影可能範囲外の場合
        guard isWithinCaptureRange else {
            if let spot = currentNearestSpot {
                let distance = String(format: "%.0f", distanceToSpot)
                return (false, "スポットまであと\(distance)mです")
            } else {
                return (false, "スタンプポイントの近くにいません")
            }
        }
        
        // 最も近いスポットがない場合
        guard let nearestSpot = currentNearestSpot else {
            return (false, "スタンプポイントが見つかりません")
        }
        
        // スポットIDが一致しない場合
        // ⚠️ UUID型で比較
        guard nearestSpot.id == spotID else {
            return (false, "このスポットは現在地と一致しません（近く: \(nearestSpot.name)）")
        }
        
        // 全ての条件をクリア
        return (true, "撮影可能です")
    }
    
    /// デバッグ用の状態文字列
    func getStatusString() -> String {
        guard let spot = currentNearestSpot else {
            return "スポット検出なし"
        }
        
        let status = isWithinCaptureRange ? "撮影可能" : "範囲外"
        let distance = String(format: "%.1fm", distanceToSpot)
        return "\(status) - \(spot.name) (\(distance))"
    }
    
    // MARK: - Manual Control
    
    /// 手動でスポットを設定（テスト用）
    func setManualSpot(_ spot: Spot, distance: CLLocationDistance = 0) {
        currentNearestSpot = spot
        distanceToSpot = distance
        isWithinCaptureRange = distance <= captureRadius
        print("🧪 手動設定: \(spot.name) (\(String(format: "%.1fm", distance)))")
    }
    
    /// 状態をリセット
    func reset() {
        currentNearestSpot = nil
        isWithinCaptureRange = false
        distanceToSpot = 0
        print("🔄 LocationAwareCaptureManagerをリセット")
    }
}

// MARK: - Preview Helper

#if DEBUG
extension LocationAwareCaptureManager {
    /// プレビュー用の便利イニシャライザ
    static func preview() -> LocationAwareCaptureManager {
        let manager = LocationAwareCaptureManager()
        // ⚠️ testSpot は Spot 型なので as Spot? は不要
        manager.setManualSpot(Spot.testSpot, distance: 15.0)
        return manager
    }
}
#endif

