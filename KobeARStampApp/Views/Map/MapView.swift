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
        RestrictedMapView(
            centerCoordinate: viewModel.centerCoordinate,
            radiusInMeters: viewModel.radiusInMeters,
            pins: mockPins
        )
        .edgesIgnoringSafeArea(.all)
//        .task {
//            await viewModel.requestPermission()
//        }
        .onReceive(NotificationCenter.default.publisher(for: .customPinTapped)) { notification in
            if let pin = notification.object as? CustomPin {
                // ここでSwiftUI側のアクション
                print("🟢 SwiftUI側で受け取ったピン: \(pin.title)")
                selectedPin = pin // 例：シート表示に使う
            }
        }
    }
}

#Preview {
    MapView()
}
