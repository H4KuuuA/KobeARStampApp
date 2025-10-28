import SwiftUI

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    @State private var isPressed = false
    @State private var activeTab: TabModel = .home
    @State private var allTabs: [AnimatedTabModel] = TabModel.allCases.compactMap { tab -> AnimatedTabModel? in
        return .init(tab: tab)
    }
    @State private var showMenu = false
    @State private var showNotification = false
    @State var showARCameraView = false
    
    var body: some View {
        // AnimationSideBarで全体をラップ
        AnimationSideBar(
            rotatesWhenExpands: true,
            disablesInteraction: true,
            sideMenuWidth: 180,
            cornerRadius: 25,
            showMenu: $showMenu
        ) { safeArea in
            // メインコンテンツ
            VStack(spacing: 0) {
                // Navigation Bar（最上部に固定）
                CustomNavigationBar(
                    onMenuTap: {
                        withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                            showMenu.toggle()
                        }
                    },
                    onNotificationTap: {
                        showNotification = true
                        print("🔔 Notification tapped")
                    },
                    showMenu: $showMenu
                )
                .padding(.top, safeArea.top)
                .background(Color.white)
                .zIndex(100) // 最前面に表示
                
                
                // Main Content
                ZStack {
                    // 地図やその他のメインコンテンツ
                    Group {
                        switch activeTab {
                        case .home:
                            MapView()
                        case .stamp:
                            StampCardView()
                        }
                    }
                    
                    // タブバーとARボタン（下部に配置）
                    VStack(spacing: 0) {
                        // StampDemoViewは.homeの時のみ表示
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
                    .zIndex(99) // タブバーも前面に表示
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
    
    /// Custom Tab Bar
    @ViewBuilder
    func CustomTabBar() -> some View {
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
        .frame(height: 48)
        .background(Color.white)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: -2)
    }
    
    /// AR Camera Button
    @ViewBuilder
    func ARCameraButton() -> some View {
        Button(action: {
            showARCameraView = true
            // カメラ起動処理
            print("🎥 AR Camera button tapped")
        }) {
            ZStack {
                // 外側の黒丸
                Circle()
                    .fill(Color("DarkBlue"))
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                
                // 内側の白縁サークル
                Circle()
                    .stroke(Color.white, lineWidth: 1.2)
                    .frame(width: 74, height: 74)
                
                // 中央の SF Symbol アイコン
                Image(systemName: "arkit")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 25, height: 25)
                    .foregroundColor(.white)
            }
        }
        .padding(.bottom, 23)
        .fullScreenCover(isPresented: $showARCameraView) {
            ARCameraView()
        }
    }
    @ViewBuilder
    func SideMenuView(_ safeArea: UIEdgeInsets) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MENU")
                .font(.largeTitle.bold())
                .foregroundColor(Color("DarkBlue"))
                .padding(.bottom, 10)
            
            SideBarButton(.home)
            SideBarButton(.stampRally)
            SideBarButton(.camera)
            SideBarButton(.notification)
            SideBarButton(.settings)
            
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
