//
//  TabView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/30.
//

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
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Navigation Bar
                CustomNavigationBar(
                    onMenuTap: {
                        showMenu = true
                    },
                    onNotificationTap: {
                        showNotification = true
                    }, showMenu: $showMenu
                )
                
                
                // Main Content
                ZStack {
                    Group {
                        switch activeTab {
                        case .home:
                            MapView()
                        case .stamp:
                            Rectangle().fill(Color.blue)
                                .ignoresSafeArea(edges: .all)
                        }
                    }
                    
                    VStack(spacing: 0) {
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
                    .ignoresSafeArea()
                }
            }
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
    }
    
    /// AR Camera Button
    @ViewBuilder
    func ARCameraButton() -> some View {
        Button(action: {
            // カメラ起動処理
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
    }
    
    
}

#Preview {
    MainTabView()
}
