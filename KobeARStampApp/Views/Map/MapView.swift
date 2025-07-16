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
                VStack {
                    Spacer()
                    
                    CardView(pin: pin) {
                        selectedPin = nil
                    }
                    .frame(maxWidth: 350)
                    .padding()
                    .padding(.bottom, 70)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedPin)
        .onReceive(NotificationCenter.default.publisher(for: .customPinTapped)) { notification in
            if let newPin = notification.object as? CustomPin {
                if selectedPin?.id != newPin.id {
                    withAnimation {
                        selectedPin = nil
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        withAnimation {
                            selectedPin = newPin
                        }
                    }
                }
            }
        }
    }
}


#Preview {
    MapView()
}
