//
//  ProximityMonitor.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/08.
//

import Foundation
import CoreLocation
import Combine
import UserNotifications

class ProximityMonitor: ObservableObject {
    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private let locationManager: LocationManager
    private var pins: [CustomPin]
    
    // 判定ロジックを担当するクラス
    private let detector: ProximityDetector
    
    // 通知管理システム
    private let notificationManager = NotificationManager.shared
    
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
        requestNotificationPermission()
    }
    
    // MARK: - Notification Permission
    
    /// 通知の許可をリクエスト
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ 通知の許可が得られました")
            } else if let error = error {
                print("⚠️ 通知の許可エラー: \(error.localizedDescription)")
            }
        }
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
        // AR表示用の既存の通知を送信
        NotificationCenter.default.post(
            name: .customPinTapped,
            object: pin
        )
        
        // 1. iPhoneのシステム通知を送信（簡潔な文章）
        sendSystemNotification(
            title: pin.title,
            body: "スポットに到着しました"
        )
        
        // 2. アプリ内通知リストに追加（詳細な文章）
        let notification = NotificationItem(
            type: .pinProximity,
            title: pin.title,
            message: "スポットに到着しました！ARスタンプを獲得できます",
            relatedPinID: pin.id.uuidString,
            metadata: [
                "latitude": String(pin.coordinate.latitude),
                "longitude": String(pin.coordinate.longitude)
            ]
        )
        notificationManager.addNotification(notification)
        
        print("📍 Entered proximity of pin: \(pin.title) (ID: \(pin.id))")
    }
    
    private func onPinSwitched(from oldPin: CustomPin, to newPin: CustomPin) {
        // AR表示の更新
        NotificationCenter.default.post(name: .customPinDeselected, object: nil)
        NotificationCenter.default.post(
            name: .customPinTapped,
            object: newPin
        )
        
        // システム通知
        sendSystemNotification(
            title: newPin.title,
            body: "スポットに到着しました"
        )
        
        // アプリ内通知
        let notification = NotificationItem(
            type: .pinProximity,
            title: newPin.title,
            message: "スポットに到着しました！ARスタンプを獲得できます",
            relatedPinID: newPin.id.uuidString
        )
        Task { @MainActor in
            notificationManager.addNotification(notification)
        }
        
        print("🔄 Switched from pin: \(oldPin.title) to pin: \(newPin.title)")
    }
    
    private func onPinExited(_ pin: CustomPin) {
        // AR表示の解除
        NotificationCenter.default.post(name: .customPinDeselected, object: nil)
        
        print("🚶 Exited proximity of pin: \(pin.title) (ID: \(pin.id))")
    }
    
    // MARK: - System Notification
    
    /// iPhoneのシステム通知を送信
    /// - Parameters:
    ///   - title: 通知のタイトル（簡潔に）
    ///   - body: 通知の本文（簡潔に）
    private func sendSystemNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // バッジ数を1に設定（iOS 16以降の推奨方法）
        content.badge = 1
        
        // すぐに通知を表示
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ システム通知の送信に失敗: \(error.localizedDescription)")
            } else {
                print("📱 システム通知を送信: \(title)")
            }
        }
    }
    
    // MARK: - Public Methods
    
    /// ピンリストを更新
    func updatePins(_ newPins: [CustomPin]) {
        self.pins = newPins
        
        // 現在アクティブなピンが新しいリストに存在しない場合は解除
        if let activePin = currentState.activePin,
           !newPins.contains(where: { $0.id.uuidString == activePin.id.uuidString }) {
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
