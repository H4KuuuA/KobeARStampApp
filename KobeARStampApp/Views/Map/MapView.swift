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
    @StateObject private var stampManager = StampManager()
    @StateObject private var proximityMonitor: ProximityMonitor
    @State private var selectedSpot: Spot? = nil
    @State private var isDetailSheetPresented = false
    @Namespace private var animation
    
    init() {
        let manager = StampManager()
        _stampManager = StateObject(wrappedValue: manager)
        _proximityMonitor = StateObject(wrappedValue: ProximityMonitor(spots: manager.allSpots))
    }
    
    var body: some View {
        ZStack {
            RestrictedMapView(
                centerCoordinate: viewModel.centerCoordinate,
                radiusInMeters: viewModel.radiusInMeters,
                spots: stampManager.allSpots
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                // マップをタップしたときにスポットの選択を解除
                NotificationCenter.default.post(name: .spotDeselected, object: nil)
            }
            
            if let spot = selectedSpot {
                VStack {
                    Spacer()
                    
                    SpotCardView(spot: spot, stampManager: stampManager) {
                        selectedSpot = nil
                    }
                    .frame(maxWidth: 350)
                    .padding()
                    .padding(.bottom, 100)
                    .onTapGesture {
                        isDetailSheetPresented = true
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedSpot)
        .sheet(isPresented: $isDetailSheetPresented) {
            if let spot = selectedSpot {
                NavigationStack {
                    StampCardDetailView(spot: spot, animation: animation, stampManager: stampManager)
                        .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotTapped)) { notification in
            if let newSpot = notification.object as? Spot {
                withAnimation {
                    selectedSpot = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        selectedSpot = newSpot
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotDeselected)) { _ in
            withAnimation {
                selectedSpot = nil
            }
        }
    }
}

#Preview {
    MapView()
}
