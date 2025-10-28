//
//  ProximtyDetector.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/08.
//

import Foundation
import CoreLocation

/// ピンとの近接状態を表す列挙型
enum ProximityState: Equatable {
    case outside               // 全てのピンから離れている
    case inside(CustomPin)     // 特定のピンの範囲内
    
    var activePin: CustomPin? {
        if case .inside(let pin) = self {
            return pin
        }
        return nil
    }
}

/// ピンとの距離情報
struct PinDistance {
    let pin: CustomPin
    let distance: CLLocationDistance
}

/// 距離ベースの近接判定を行うクラス
class ProximityDetector {
    // MARK: - Properties
    
    /// 侵入判定の半径（メートル）
    let entryRadius: CLLocationDistance
    
    /// 退出判定の半径（メートル）- ヒステリシス用
    let exitRadius: CLLocationDistance
    
    // MARK: - Initialization
    
    init(entryRadius: CLLocationDistance = 25.0, exitRadius: CLLocationDistance = 35.0) {
        self.entryRadius = entryRadius
        self.exitRadius = exitRadius
    }
    
    // MARK: - Public Methods
    
    /// 現在地とピン配列から、新しい近接状態を判定する
    /// - Parameters:
    ///   - currentLocation: 現在地
    ///   - pins: 判定対象のピン配列
    ///   - previousState: 前回の状態（ヒステリシス判定に使用）
    /// - Returns: 新しい近接状態
    func detectProximityState(
        currentLocation: CLLocation,
        pins: [CustomPin],
        previousState: ProximityState
    ) -> ProximityState {
        
        // 各ピンとの距離を計算
        let pinsWithDistance = calculateDistances(from: currentLocation, to: pins)
        
        // 距離でソート（近い順）
        let sortedPins = pinsWithDistance.sorted { $0.distance < $1.distance }
        
        // 最も近いピンを取得
        guard let nearest = sortedPins.first else {
            return .outside
        }
        
        // 前回の状態に応じて判定
        switch previousState {
        case .outside:
            // 圏外 → 侵入判定
            return detectEntryFromOutside(nearest: nearest)
            
        case .inside(let activePin):
            // 圏内 → 状態維持 or 退出 or 切り替え
            return detectStateChangeFromInside(
                activePin: activePin,
                nearest: nearest
            )
        }
    }
    
    /// 各ピンとの距離を計算
    /// - Parameters:
    ///   - location: 基準位置
    ///   - pins: ピン配列
    /// - Returns: 距離情報の配列
    func calculateDistances(
        from location: CLLocation,
        to pins: [CustomPin]
    ) -> [PinDistance] {
        return pins.map { pin in
            let pinLocation = CLLocation(
                latitude: pin.coordinate.latitude,
                longitude: pin.coordinate.longitude
            )
            let distance = location.distance(from: pinLocation)
            
            return PinDistance(pin: pin, distance: distance)
        }
    }
    
    /// 2つのピンが同一かを判定
    func isSamePin(_ pin1: CustomPin, _ pin2: CustomPin) -> Bool {
        return pin1.id == pin2.id
    }
    
    // MARK: - Private Methods
    
    /// 圏外状態からの侵入判定
    private func detectEntryFromOutside(nearest: PinDistance) -> ProximityState {
        if nearest.distance <= entryRadius {
            return .inside(nearest.pin)
        } else {
            return .outside
        }
    }
    
    /// 圏内状態からの状態変化判定
    private func detectStateChangeFromInside(
        activePin: CustomPin,
        nearest: PinDistance
    ) -> ProximityState {
        
        if isSamePin(activePin, nearest.pin) {
            // 同じピンが最も近い場合
            if nearest.distance > exitRadius {
                // 退出判定（ヒステリシス適用）
                return .outside
            } else {
                // 状態維持（entryRadius〜exitRadiusの間）
                return .inside(activePin)
            }
        } else {
            // 別のピンが最も近くなった
            if nearest.distance <= entryRadius {
                // 新しいピンの圏内に侵入
                return .inside(nearest.pin)
            } else {
                // どのピンも圏内ではない
                return .outside
            }
        }
    }
}

// MARK: - Debug Extension
extension ProximityState: CustomStringConvertible {
    var description: String {
        switch self {
        case .outside:
            return "Outside all pins"
        case .inside(let pin):
            return "Inside pin: \(pin.title) (ID: \(pin.id))"
        }
    }
}
