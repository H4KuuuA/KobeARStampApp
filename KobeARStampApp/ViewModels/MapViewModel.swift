//
//  MapViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

import SwiftUI
import  MapKit
import Combine

class MapViewModel: ObservableObject {
    
    @Published var centerCoordinate = CLLocationCoordinate2D(
        latitude: 34.70602173020105,
        longitude: 135.2162279954511
    )
    @Published var radiusInMeters: CLLocationDistance = 1500
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = LocationManager.shared
    
    init() {
        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (lat: Double, lon: Double) in
                guard lat != 0.0, lon != 0.0 else { return }
                // 必要があれば現在地でカメラ位置変更などをここで対応
            }
            .store(in: &cancellables)
    }
    
    func requestPermission() async {
        await locationManager.requestLocationPermissionIfNeeded()
    }
}
