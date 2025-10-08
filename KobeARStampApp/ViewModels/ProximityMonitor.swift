//
//  ProximityMonitor.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/08.
//

import Foundation
import CoreLocation
import Combine

class ProximityMonitor: ObservableObject {
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private var pins: [CustomPin]
    
    // 判定ロジックを担当するクラス
    private let detector: ProximityDetector
    
    // 現在の近接状態
    private var currentState: ProximityState = .outside
    
    // MARK: - Initialization
    init(
        locationManager: LocationManager = .shared,
        pins: [CustomPin],
        detector: ProximityDetector = ProximityDetector()
    ) {
        self.locationManager = locationManager
        self.pins = pins
        self.detector = detector
        
        setupLocationObserver()
    }
    
    // MARK: - Setup
    private func setupLocationObserver() {
        // LocationManagerの位置情報更新を購読
        Publishers.CombineLatest(
            locationManager.$latitude,
            locationManager.$longitude
        )
        .dropFirst() // 初期値をスキップ
        .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main) // 過剰な更新を防ぐ
        .sink { [weak self] lat, lon in
            guard let self = self else { return }
            self.handleLocationUpdate(latitude: lat, longitude: lon)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Location Update Handling
    private func handleLocationUpdate(latitude: Double, longitude: Double) {
        let currentLocation = CLLocation(latitude: latitude, longitude: longitude)
        
        // ProximityDetectorで状態を判定
        let newState = detector.detectProximityState(
            currentLocation: currentLocation,
            pins: pins,
            previousState: currentState
        )
        
        // 状態が変化した場合のみ処理
        if newState != currentState {
            handleStateChange(from: currentState, to: newState)
            currentState = newState
        }
    }
    
    // MARK: - State Change Handling
    private func handleStateChange(from oldState: ProximityState, to newState: ProximityState) {
        switch (oldState, newState) {
        case (.outside, .inside(let pin)):
            // 圏外 → 圏内: 侵入
            onPinEntered(pin)
            
        case (.inside(let oldPin), .inside(let newPin)):
            // 圏内 → 別の圏内: ピン切り替え
            if !detector.isSamePin(oldPin, newPin) {
                onPinSwitched(from: oldPin, to: newPin)
            }
            
        case (.inside(let pin), .outside):
            // 圏内 → 圏外: 退出
            onPinExited(pin)
            
        case (.outside, .outside):
            // 変化なし（通常ここには来ない）
            break
        }
    }
    
    // MARK: - Event Handlers
    private func onPinEntered(_ pin: CustomPin) {
        // タップ通知と同じ通知を送信（既存のアニメーションが発火）
        NotificationCenter.default.post(
            name: .customPinTapped,
            object: pin
        )
        
        print("📍 Entered proximity of pin: \(pin.title) (ID: \(pin.id))")
    }
    
    private func onPinSwitched(from oldPin: CustomPin, to newPin: CustomPin) {
        // 古いピンを解除してから新しいピンをアクティブに
        NotificationCenter.default.post(name: .customPinDeselected, object: nil)
        
        NotificationCenter.default.post(
            name: .customPinTapped,
            object: newPin
        )
        
        print("🔄 Switched from pin: \(oldPin.title) to pin: \(newPin.title)")
    }
    
    private func onPinExited(_ pin: CustomPin) {
        // 解除通知を送信
        NotificationCenter.default.post(name: .customPinDeselected, object: nil)
        
        print("🚶 Exited proximity of pin: \(pin.title) (ID: \(pin.id))")
    }
    
    // MARK: - Public Methods
    
    /// ピンリストを更新
    func updatePins(_ newPins: [CustomPin]) {
        self.pins = newPins
        
        // 現在アクティブなピンが新しいリストに存在しない場合は解除
        if let activePin = currentState.activePin,
           !newPins.contains(where: { $0.id == activePin.id }) {
            onPinExited(activePin)
            currentState = .outside
        }
    }
    
    /// 手動でピンをアクティブにする（タップ時など）
    func manuallySelectPin(_ pin: CustomPin) {
        currentState = .inside(pin)
    }
    
    /// 手動でピンを解除する
    func manuallyDeselectPin() {
        currentState = .outside
    }
    
    /// 現在の状態を取得（デバッグ用）
    func getCurrentState() -> ProximityState {
        return currentState
    }
}
