//
//  TabView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/30.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTabIndex = 0
    
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
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 64, height: 64)
                            .foregroundColor(.accentColor)
                            .shadow(radius: 4)
                    }
                    
                    Spacer()
                }
                .padding(.bottom,8)
            }
        }
    }
}

#Preview {
    MainTabView()
}
