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
    @State private var selectedPin: CustomPin? = nil
    
    var body: some View {
        ZStack {
            RestrictedMapView(
                centerCoordinate: viewModel.centerCoordinate,
                radiusInMeters: viewModel.radiusInMeters,
                pins: mockPins
            )
            .edgesIgnoringSafeArea(.all)
            
            if let pin = selectedPin {
                CardView(pin: pin) {
                    selectedPin = nil
                }
                .frame(maxWidth: 350)
                .padding()
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .customPinTapped)) { notification in
            if let pin = notification.object as? CustomPin {
                selectedPin = pin
            }
        }
        .animation(.easeInOut, value: selectedPin)
    }
}


#Preview {
    MapView()
}
