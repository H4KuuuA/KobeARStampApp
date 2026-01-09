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
    private var spots: [Spot]
    
    // 判定ロジックを担当するクラス
    private let detector: ProximityDetector
    
    // 通知管理システム
    private let notificationManager = NotificationManager.shared
    
    // 現在の近接状態
    private var currentState: ProximityStateSpot = .outside
    
    // MARK: - Initialization
    init(
        locationManager: LocationManager = .shared,
        spots: [Spot],
        detector: ProximityDetector = ProximityDetector()
    ) {
        self.locationManager = locationManager
        self.spots = spots
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
        let newState = detector.detectProximityStateForSpot(
            currentLocation: currentLocation,
            spots: spots,
            previousState: currentState
        )
        
        // 状態が変化した場合のみ処理
        if newState != currentState {
            handleStateChange(from: currentState, to: newState)
            currentState = newState
        }
    }
    
    // MARK: - State Change Handling
    private func handleStateChange(from oldState: ProximityStateSpot, to newState: ProximityStateSpot) {
        switch (oldState, newState) {
        case (.outside, .inside(let spot)):
            // 圏外 → 圏内: 侵入
            onSpotEntered(spot)
            
        case (.inside(let oldSpot), .inside(let newSpot)):
            // 圏内 → 別の圏内: スポット切り替え
            if oldSpot.id != newSpot.id {
                onSpotSwitched(from: oldSpot, to: newSpot)
            }
            
        case (.inside(let spot), .outside):
            // 圏内 → 圏外: 退出
            onSpotExited(spot)
            
        case (.outside, .outside):
            // 変化なし(通常ここには来ない)
            break
        }
    }
    
    // MARK: - Event Handlers
    private func onSpotEntered(_ spot: Spot) {
        // AR表示用の通知を送信（接近時は波形エフェクト）
        print("📤 ProximityMonitor: .spotProximityEntered 通知を送信 - \(spot.name)")
        NotificationCenter.default.post(
            name: .spotProximityEntered,
            object: spot
        )
        
        // 1. iPhoneのシステム通知を送信(簡潔な文章)
        sendSystemNotification(
            title: spot.name,
            body: "スポットに到着しました"
        )
        
        // 2. アプリ内通知リストに追加(詳細な文章)
        let notification = NotificationItem(
            type: .pinProximity,
            title: spot.name,
            message: "スポットに到着しました!ARスタンプを獲得できます",
            relatedPinID: spot.id.uuidString,
            metadata: [
                "latitude": String(spot.coordinate.latitude),
                "longitude": String(spot.coordinate.longitude)
            ]
        )
        notificationManager.addNotification(notification)
        
        print("📍 Entered proximity of spot: \(spot.name) (ID: \(spot.id))")
    }
    
    private func onSpotSwitched(from oldSpot: Spot, to newSpot: Spot) {
        // AR表示の更新（接近時は波形エフェクト）
        NotificationCenter.default.post(name: .spotDeselected, object: nil)
        print("📤 ProximityMonitor: .spotProximityEntered 通知を送信 - \(newSpot.name)")
        NotificationCenter.default.post(
            name: .spotProximityEntered,
            object: newSpot
        )
        
        // システム通知
        sendSystemNotification(
            title: newSpot.name,
            body: "スポットに到着しました"
        )
        
        // アプリ内通知
        let notification = NotificationItem(
            type: .pinProximity,
            title: newSpot.name,
            message: "スポットに到着しました!ARスタンプを獲得できます",
            relatedPinID: newSpot.id.uuidString
        )
        Task { @MainActor in
            notificationManager.addNotification(notification)
        }
        
        print("🔄 Switched from spot: \(oldSpot.name) to spot: \(newSpot.name)")
    }
    
    private func onSpotExited(_ spot: Spot) {
        // AR表示の解除
        NotificationCenter.default.post(name: .spotDeselected, object: nil)
        
        print("🚶 Exited proximity of spot: \(spot.name) (ID: \(spot.id))")
    }
    
    // MARK: - System Notification
    
    /// iPhoneのシステム通知を送信
    /// - Parameters:
    ///   - title: 通知のタイトル(簡潔に)
    ///   - body: 通知の本文(簡潔に)
    private func sendSystemNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        // バッジ数を1に設定(iOS 16以降の推奨方法)
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
    
    /// スポットリストを更新
    func updateSpots(_ newSpots: [Spot]) {
        self.spots = newSpots
        
        // 現在アクティブなスポットが新しいリストに存在しない場合は解除
        if let activeSpot = currentState.activeSpot,
           !newSpots.contains(where: { $0.id == activeSpot.id }) {
            onSpotExited(activeSpot)
            currentState = .outside
        }
    }
    
    /// 手動でスポットをアクティブにする(タップ時など)
    func manuallySelectSpot(_ spot: Spot) {
        currentState = .inside(spot)
    }
    
    /// 手動でスポットを解除する
    func manuallyDeselectSpot() {
        currentState = .outside
    }
    
    /// 現在の状態を取得(デバッグ用)
    func getCurrentState() -> ProximityStateSpot {
        return currentState
    }
}

// MARK: - ProximityState for Spot

enum ProximityStateSpot: Equatable {
    case outside
    case inside(Spot)
    
    var activeSpot: Spot? {
        if case .inside(let spot) = self {
            return spot
        }
        return nil
    }
    
    static func == (lhs: ProximityStateSpot, rhs: ProximityStateSpot) -> Bool {
        switch (lhs, rhs) {
        case (.outside, .outside):
            return true
        case (.inside(let lhsSpot), .inside(let rhsSpot)):
            return lhsSpot.id == rhsSpot.id
        default:
            return false
        }
    }
}

// MARK: - ProximityDetector Extension for Spot

extension ProximityDetector {
    
    /// Spot用の近接状態判定
    func detectProximityStateForSpot(
        currentLocation: CLLocation,
        spots: [Spot],
        previousState: ProximityStateSpot
    ) -> ProximityStateSpot {
        
        guard let nearestSpot = findNearestSpot(from: currentLocation, in: spots) else {
            return .outside
        }
        
        return .inside(nearestSpot.spot)
    }
}

