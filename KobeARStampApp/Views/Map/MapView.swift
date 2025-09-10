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
    @State private var isDetailSheetPresented = false
    
    var body: some View {
        ZStack {
            RestrictedMapView(
                centerCoordinate: viewModel.centerCoordinate,
                radiusInMeters: viewModel.radiusInMeters,
                pins: mockPins
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                // マップをタップしたときにピンの選択を解除
                NotificationCenter.default.post(name: .customPinDeselected, object: nil)
            }
            
            if let pin = selectedPin {
                VStack {
                    Spacer()
                    
                    CardView(pin: pin) {
                        selectedPin = nil
                    }
                    .frame(maxWidth: 350)
                    .padding()
                    .padding(.bottom, 70)
                    .onTapGesture {
                        isDetailSheetPresented = true
                    }
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedPin)
        .sheet(isPresented: $isDetailSheetPresented) {
            if let pin = selectedPin {
                PinDetailSheetView(pin: pin)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.visible)
            }
        }

        .onReceive(NotificationCenter.default.publisher(for: .customPinTapped)) { notification in
            if let newPin = notification.object as? CustomPin {
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
        // ★ 追加：ピン以外がタップされたときにカードも閉じる
        .onReceive(NotificationCenter.default.publisher(for: .customPinDeselected)) { _ in
            withAnimation {
                selectedPin = nil
            }
        }
    }
}

#Preview {
    MapView()
}
