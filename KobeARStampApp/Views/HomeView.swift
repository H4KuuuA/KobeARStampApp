//
//  HomeView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/02.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var bannerManager = EventBannerManager.shared
    
    var body: some View {
        ZStack {
            MainTabView()
                .preferredColorScheme(.light)
            
            // イベントバナー（全画面オーバーレイ）
            if bannerManager.shouldShowBanner, let event = bannerManager.currentEvent {
                ZStack {
                    // 半透明の背景
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .onTapGesture {
                            bannerManager.dismissBanner()
                        }
                    
                    // バナー本体
                    EventBannerView(event: event) {
                        bannerManager.dismissBanner()
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                .zIndex(999)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: bannerManager.shouldShowBanner)
        .task {
            // task は onAppear と違い、Viewのライフサイクルで1回だけ確実に実行される
            print("🏠 HomeView task started")
            
            #if DEBUG
            // デバッグ時は毎回表示履歴をリセット（テスト用）
            bannerManager.resetShowHistory()
            print("🔄 Banner history reset for testing")
            #endif
            
            // 少し遅延させてイベント取得完了を待つ
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5秒
            
            await MainActor.run {
                bannerManager.checkAndShowBannerFromStampManager()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(AppLoaderViewModel())
}
