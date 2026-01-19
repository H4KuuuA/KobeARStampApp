//
//  MapViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

import SwiftUI
import MapKit
import Combine

class MapViewModel: ObservableObject {
    
    @Published var centerCoordinate = CLLocationCoordinate2D(
        latitude: 34.69973564179591,
        longitude: 135.19311499645997
    )
    @Published var radiusInMeters: CLLocationDistance = 1500
    
    private var cancellables = Set<AnyCancellable>()
    private let locationManager = LocationManager.shared
    private var didSetCenter = false
    
    init() {
        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (lat: Double, lon: Double) in
                guard lat != 0.0, lon != 0.0 else { return }
                guard let self = self, !self.didSetCenter else { return }
                self.centerCoordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                self.didSetCenter = true
            }
            .store(in: &cancellables)
    }
}
