//
//  MainTabView.swift (修正版)
//  ARCameraButton部分を修正
//

import SwiftUI
import CoreLocation

struct MainTabView: View {
    @State private var activeTab: TabModel = .home
    @State private var allTabs: [AnimatedTabModel] = [
        .home,
        .stamp
    ].compactMap { tab -> AnimatedTabModel? in
        return .init(tab: tab)
    }
    
    @State private var showMenu = false
    @State private var showNotification = false
    @State var showARCameraView = false
    
    // ✅ 追加: LocationManagerとProximityDetector
    @StateObject private var locationManager = LocationManager.shared
    private let proximityDetector = ProximityDetector()
    @ObservedObject private var stampManager = StampManager.shared
    
    var body: some View {
        AnimationSideBar(
            rotatesWhenExpands: true,
            disablesInteraction: true,
            sideMenuWidth: 180,
            cornerRadius: 25,
            showMenu: $showMenu
        ) { safeArea in
            VStack(spacing: 0) {
                CustomNavigationBar(
                    onMenuTap: {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu.toggle()
                        }
                    },
                    onNotificationTap: {
                        showNotification = true
                    },
                    showMenu: $showMenu
                )
                .padding(.top, safeArea.top)
                .background(Color.white)
                .zIndex(100)
                
                ZStack {
                    Group {
                        switch activeTab {
                        case .home:
                            MapView()
                        case .stamp:
                            StampCardView(stampManager: StampManager.shared)
                        case .settings:
                            SettingsView()
                        }
                    }
                    
                    VStack(spacing: 0) {
                        if activeTab == .home {
                            StampDemoView()
                        }
                        
                        Spacer()
                        
                        ZStack {
                            CustomTabBar()
                            VStack {
                                HStack {
                                    Spacer()
                                    ARCameraButton()
                                    Spacer()
                                }
                            }
                        }
                    }
                    .zIndex(99)
                }
            }
            .sheet(isPresented: $showNotification) {
                LocalNotificationListView()
            }
            
        } menuView: { safeArea in
            SideMenuView(safeArea)
        } background: {
            Color("menu_background_color")
        }
    }
    
    // MARK: - Components
    
    @ViewBuilder
    func CustomTabBar() -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white)
                .offset(y: 16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
            
            HStack(spacing: 60) {
                ForEach($allTabs) { $animatedTab in
                    let tab = animatedTab.tab
                    
                    VStack(spacing: 4) {
                        Image(systemName: tab.rawValue)
                            .font(.title2)
                            .symbolEffect(.bounce.down.byLayer, value: animatedTab.isAnimating)
                        Text(tab.title)
                            .font(.caption)
                            .textScale(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundStyle(activeTab == tab ? Color("DarkBlue") : Color.gray.opacity(0.8))
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    .contentShape(.rect)
                    .onTapGesture {
                        withAnimation(.bouncy, completionCriteria: .logicallyComplete, {
                            activeTab = tab
                            animatedTab.isAnimating = true
                        }, completion: {
                            var transaction = Transaction()
                            transaction.disablesAnimations = true
                            withTransaction(transaction) {
                                animatedTab.isAnimating = nil
                            }
                        })
                    }
                }
            }
            .offset(y: 6)
        }
        .frame(height: 48)
    }
    
    // MARK: - ✅ 修正: 最寄りスポットを自動選択
    
    @ViewBuilder
    func ARCameraButton() -> some View {
        Button(action: {
            showARCameraView = true
        }) {
            ZStack {
                Circle()
                    .fill(Color("DarkBlue"))
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                
                Circle()
                    .stroke(Color.white, lineWidth: 1.2)
                    .frame(width: 74, height: 74)
                
                Image(systemName: "arkit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 23)
        .fullScreenCover(isPresented: $showARCameraView) {
            // ✅ 修正: 最寄りスポットを動的に選択
            let targetSpot = getNearestSpot()
            
            ARCameraView(
                spot: targetSpot,
                activeTab: .constant(.home),
                stampManager: stampManager
            )
        }
        .offset(y: 4)
    }
    
    /// ✅ 最寄りスポットを取得（見つからない場合はフォールバック）
    private func getNearestSpot() -> Spot {
        // 位置情報が取得できているか確認
        guard locationManager.latitude != 0.0,
              locationManager.longitude != 0.0 else {
            print("⚠️ 位置情報未取得 - フォールバック使用")
            return stampManager.allSpots.first ?? Spot.testSpot
        }
        
        let currentLocation = CLLocation(
            latitude: locationManager.latitude,
            longitude: locationManager.longitude
        )
        
        // ProximityDetectorで最寄りスポットを検索（距離制限なし）
        let allDistances = proximityDetector.calculateDistances(
            from: currentLocation,
            to: stampManager.allSpots
        )
        
        if let nearest = allDistances.min(by: { $0.distance < $1.distance }) {
            print("✅ 最寄りスポット選択: \(nearest.spot.name) - \(String(format: "%.1fm", nearest.distance))")
            return nearest.spot
        } else {
            print("⚠️ スポットが見つかりません - フォールバック使用")
            return stampManager.allSpots.first ?? Spot.testSpot
        }
    }
    
    @ViewBuilder
    func SideMenuView(_ safeArea: UIEdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MENU")
                .font(.largeTitle.bold())
                .foregroundColor(Color("DarkBlue"))
                .padding(.bottom, 10)
            
            SideBarButton(.home) {
                activeTab = .home
                withAnimation { showMenu = false }
            }
            
            SideBarButton(.stampRally) {
                activeTab = .stamp
                withAnimation { showMenu = false }
            }
            
            SideBarButton(.camera) {
                withAnimation { showMenu = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showARCameraView = true
                }
            }
            
            SideBarButton(.notification) {
                withAnimation { showMenu = false }
                showNotification = true
            }
            
            SideBarButton(.settings) {
                activeTab = .settings
                withAnimation { showMenu = false }
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
        .padding(.top, safeArea.top)
        .padding(.bottom, safeArea.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .environment(\.colorScheme, .dark)
    }
    
    @ViewBuilder
    func SideBarButton(_ tab: SideMenuTab, onTap: @escaping () -> () = { }) -> some View {
        Button(action: onTap, label: {
            HStack (spacing:12){
                Image(systemName: tab.rawValue)
                    .font(.title3)
                
                Text(tab.title)
                    .font(.callout)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 10)
            .contentShape(.rect)
            .foregroundStyle(Color.black)
        })
    }
}

#Preview {
    MainTabView()
}
