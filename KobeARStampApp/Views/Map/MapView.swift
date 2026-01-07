import SwiftUI
import MapKit

// MARK: - MapView
struct MapView: View {
    @StateObject private var viewModel = MapViewModel()
    @ObservedObject private var stampManager = StampManager.shared
    @StateObject private var proximityMonitor: ProximityMonitor
    @State private var selectedSpot: Spot? = nil
    @State private var isDetailSheetPresented = false
    @State private var shouldCenterOnUser = false
    @State private var shouldResetNorth = false
    @Namespace private var animation
    
    init() {
        _proximityMonitor = StateObject(wrappedValue: ProximityMonitor(spots: StampManager.shared.allSpots))
    }
    
    // MapViewでは常に現在開催中のイベントのスポットのみ表示
    private var displayedSpots: [Spot] {
        if let currentEvent = stampManager.currentEvent, !stampManager.currentEventSpots.isEmpty {
            return stampManager.currentEventSpots
        } else {
            return stampManager.allSpots
        }
    }
    
    var body: some View {
        ZStack {
            RestrictedMapView(
                centerCoordinate: viewModel.centerCoordinate,
                radiusInMeters: viewModel.radiusInMeters,
                spots: displayedSpots,
                shouldCenterOnUser: $shouldCenterOnUser,
                shouldResetNorth: $shouldResetNorth
            )
            .edgesIgnoringSafeArea(.all)
            .onTapGesture {
                NotificationCenter.default.post(name: .spotDeselected, object: nil)
            }
            
            // ローディングインジケーター(中央)
            if stampManager.isLoadingSpots {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
            }
            
            // マップコントロールボタン(右下)
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        // 北向きボタン
                        NorthButton {
                            shouldResetNorth = true
                        }
                        
                        // 現在地ボタン
                        CurrentLocationButton {
                            shouldCenterOnUser = true
                        }
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 120)
                }
            }
            .zIndex(0)
            
            // スポットカード(下部)
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
                    // MapViewから表示する時はスクロール無効
                    StampCardDetailView(
                        spot: spot,
                        animation: animation,
                        stampManager: stampManager,
                        spots: displayedSpots,
                        isScrollEnabled: false
                    )
                    .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
        }
        .task {
            // 起動時に現在開催中のイベントを取得し、そのスポットを読み込む
            await stampManager.fetchCurrentEvent()
            if let currentEvent = stampManager.currentEvent {
                await stampManager.fetchSpots(for: currentEvent)
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

// MARK: - North Button
struct NorthButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                
                Image(systemName: "safari")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("DarkBlue"))
            }
        }
    }
}

// MARK: - Current Location Button
struct CurrentLocationButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 2)
                
                Image(systemName: "location.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Color("DarkBlue"))
            }
        }
    }
}

#Preview {
    MapView()
}
