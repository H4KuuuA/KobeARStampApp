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
                selectedPin = pin
            }
        }
        .sheet(item: $selectedPin) { pin in
            VStack(alignment: .leading, content: {
                HStack {
                    Spacer()
                    Button {
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.gray.opacity(0.8))
                            .font(.title2)
                    }
                    
                }
            })
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .presentationDetents([.height(80), .medium, .large])
            .presentationCornerRadius(20)
            .presentationBackground(.regularMaterial)
            .presentationBackgroundInteraction(.enabled(upThrough: .large))
        }
    }
}

#Preview {
    MapView()
}
