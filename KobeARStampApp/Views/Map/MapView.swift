//
//  MapView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/04.
//

import SwiftUI
import MapKit

struct MapView: View {
    @State private var cameraPosition : MapCameraPosition = .region (
        MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 34.7050, longitude: 135.2410),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
    )
    @ObservedObject private var locationManager = LocationManager.shared
    
    var body: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            // 必要なら他のピンもここで追加可能
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onReceive(locationManager.$latitude.combineLatest(locationManager.$longitude)) { lat, lon in
                    guard lat != 0.0 && lon != 0.0 else { return }

                    DispatchQueue.main.async {
                        let region = MKCoordinateRegion(
                            center: CLLocationCoordinate2D(latitude: lat, longitude: lon),
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                        cameraPosition = .region(region)
                    }
                }
        .onAppear {
            Task {
                await locationManager.requestLocationPermissionIfNeeded()
            }
        }
        .ignoresSafeArea()
    }
}

#Preview {
    MapView()
}
