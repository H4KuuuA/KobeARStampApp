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
    @State private var showSheet : Bool = false
    
    var body: some View {
        ZStack {
            Group {
                switch activeTab {
                case .home:
                    // Text("HomeView()")
                    Rectangle().fill(Color.red)
                        .ignoresSafeArea(edges: .all)
                case .stamp:
                    // Text("StampView()")
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
        .task {
            showSheet = true
        }
        .sheet(isPresented: $showSheet) {
            VStack(alignment: .leading, content: {
                HStack {
                    Spacer()
                    Button {
                        showSheet = false
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
                .foregroundStyle(activeTab == tab ? Color.primary : Color .gray.opacity(0.8))
                .padding(.top, 15)
                .padding(.bottom, 10)
                .contentShape(.rect)
                .onTapGesture {
                    withAnimation(.bouncy, completionCriteria :.logicallyComplete, {
                        activeTab = tab
                        animatedTab.isAnimating = true
                    }, completion: {
                        var transction = Transaction()
                        transction.disablesAnimations = true
                        withTransaction(transction) {
                            animatedTab.isAnimating = nil
                        }
                    })
                }
            }
        }
        .frame(height: 48)
        .background(.regularMaterial)
    }
    
    /// AR Camera Button
    @ViewBuilder
    func ARCameraButton() -> some View {
        Button(action:{
            // カメラ起動
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color("LightBlue"),
                                Color("DarkBlue")
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 72, height: 72) // サイズ調整（円）
                    .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1.2)
                    )
                VStack(spacing: 0) {
                    Text("AR")
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Image(systemName: "camera")
                        .resizable()
                        .scaledToFit()
                        .fontWeight(.medium)
                        .frame(width: 42, height: 42)
                        .foregroundColor(.white)
                }
            }
            .scaleEffect(isPressed ? 0.92 : 1.0) // 小さくして戻す
            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isPressed)
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in
                    isPressed = false
                    // タップ完了後の処理はここで実行してもOK
                }
        )
        .shadow(color: Color.black.opacity(0.2), radius: 1, x: 0, y: 2)
        .padding(.bottom, 28)
    }
    
}

#Preview {
    MainTabView()
}
