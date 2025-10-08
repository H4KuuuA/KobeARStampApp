//
//  LocationManagerModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/04.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    @Published var latitude: Double = 0.0
    @Published var longitude: Double = 0.0
    
    private var locationContinuation: CheckedContinuation<Void, Never>?
    private var locationManager = CLLocationManager()
    
    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10
        
        // デリゲートメソッドで処理するため、ここでは権限チェックのみ
        checkInitialAuthorizationStatus()
    }
    
    private func checkInitialAuthorizationStatus() {
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // 権限が未決定の場合のみリクエスト
            // デリゲートメソッドで結果を受け取る
            DispatchQueue.global(qos: .userInitiated).async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        case .authorizedWhenInUse, .authorizedAlways:
            // すでに許可されている場合は位置情報の更新を開始
            startLocationUpdates()
        case .denied, .restricted:
            print("位置情報の使用が拒否されています")
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            print("位置情報の使用が拒否されました")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    private func startLocationUpdates() {
        guard CLLocationManager.locationServicesEnabled() else { return }
        
        // バックグラウンドスレッドで実行
        DispatchQueue.global(qos: .userInitiated).async {
            self.locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        DispatchQueue.main.async {
            self.latitude = newLocation.coordinate.latitude
            self.longitude = newLocation.coordinate.longitude
            self.locationContinuation?.resume()
            self.locationContinuation = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("位置情報の取得に失敗: \(error.localizedDescription)")
    }
    
    func requestLocationPermissionIfNeeded() async {
        guard latitude == 0.0 && longitude == 0.0 else { return }
        await withCheckedContinuation { continuation in
            self.locationContinuation = continuation
        }
    }
}
