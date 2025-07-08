//
//  MapView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/04.
//


import SwiftUI
import MapKit

struct MapView: View {
    @StateObject private var viewModel = MapViewModel()

    var body: some View {
        RestrictedMapView(
            centerCoordinate: viewModel.centerCoordinate,
            radiusInMeters: viewModel.radiusInMeters,
            pins: mockPins
        )
        .edgesIgnoringSafeArea(.all)
        .task {
            await viewModel.requestPermission()
        }
    }
}

#Preview {
    MapView()
}
