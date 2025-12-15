//
//  MainTabView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/08/01.
//

import SwiftUI

struct MainTabView: View {
    // MARK: - Properties
    @State private var activeTab: TabModel = .home
    
    // 下のタブバーに表示する項目だけを定義
    // (.settings はTabModelに含まれますが、下のバーには表示したくないため除外しています)
    @State private var allTabs: [AnimatedTabModel] = [
        .home,
        .stamp
    ].compactMap { tab -> AnimatedTabModel? in
        return .init(tab: tab)
    }
    
    @State private var showMenu = false
    @State private var showNotification = false
    @State var showARCameraView = false
    
    // MARK: - Body
    var body: some View {
        AnimationSideBar(
            rotatesWhenExpands: true,
            disablesInteraction: true,
            sideMenuWidth: 180,
            cornerRadius: 25,
            showMenu: $showMenu
        ) { safeArea in
            VStack(spacing: 0) {
                // ナビゲーションバー
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
                
                // メインコンテンツエリア
                ZStack {
                    // タブに応じた画面の切り替え
                    Group {
                        switch activeTab {
                        case .home:
                            MapView()
                        case .stamp:
                            StampCardView(stampManager: StampManager())
                        case .settings:
                            SettingsView()
                        }
                    }
                    
                    // 下部のタブバーとARボタン
                    // 設定画面の時も表示したままで良ければこのまま。
                    // 隠したい場合は `if activeTab != .settings` で囲ってください。
                    VStack(spacing: 0) {
                        // ホーム画面の時だけデモボタンなどを表示する例
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
            // Rectangleを背景として配置
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
                    // activeTabと一致する時だけ色を変える（設定画面表示中はどれもグレーになる）
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
            .offset(y: 12)
        }
        .frame(height: 48)
    }
    
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
            let previewSpot = StampManager().allSpots.first ?? Spot(id: "preview-spot", name: "Preview Spot", placeholderImageName: "questionmark.circle", modelName: "box.usdz")
            
            ARCameraView(spot: previewSpot,
                         activeTab: .constant(.home),
                         stampManager: StampManager())
        }
        .offset(y: 4)
    }
    
    @ViewBuilder
    func SideMenuView(_ safeArea: UIEdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MENU")
                .font(.largeTitle.bold())
                .foregroundColor(Color("DarkBlue"))
                .padding(.bottom, 10)
            
            // 1. ホーム
            SideBarButton(.home) {
                activeTab = .home
                withAnimation { showMenu = false }
            }
            
            // 2. スタンプカード
            SideBarButton(.stampRally) {
                activeTab = .stamp
                withAnimation { showMenu = false }
            }
            
            // 3. カメラ
            SideBarButton(.camera) {
                withAnimation { showMenu = false }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    showARCameraView = true
                }
            }
            
            // 4. 通知
            SideBarButton(.notification) {
                withAnimation { showMenu = false }
                showNotification = true
            }
            
            // 5. 設定
            SideBarButton(.settings) {
                // ここでSettingsViewに切り替える
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
