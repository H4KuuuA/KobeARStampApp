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
    
    var body: some View {
        ZStack {
            TabView(selection: $selectedTabIndex) {
                Text("HomeView()")
                    .tag(0)
                    .tabItem {
                        Image(systemName: "house")
                        Text("ホーム")
                    }
                // ダミータブ
                Color.clear
                    .tag(1)
                    .tabItem {
                        // タブアイコンは空にする
                        EmptyView()
                    }
                Text("StampView()")
                    .tag(2)
                    .tabItem {
                        Image(systemName: "menucard")
                        Text("スタンプカード")
                    }
            }
            .tint(.primary)
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    
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
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
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
                    
                    Spacer()
                }
                .padding(.bottom,6)
            }
        }
    }
}

#Preview {
    MainTabView()
}
