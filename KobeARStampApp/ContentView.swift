//
//  ContentView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/27.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appLoader = AppLoaderViewModel()
    @ObservedObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                // ログイン済みの場合
                if appLoader.isLoading {
                    // ✅ 差分チェック中 or 同期中 → LoadingView表示
                    LoadingView(appLoader: appLoader)
                } else {
                    // ✅ チェック完了 → HomeView表示
                    HomeView()
                }
            } else {
                // 未ログインの場合
                LoginView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appLoader.isLoading)
        .task(id: authManager.isAuthenticated) {
            // ✅ ログイン状態がtrueの場合、差分チェック開始
            if authManager.isAuthenticated {
                await appLoader.checkAndSyncIfNeeded()
                
                // ✅ データ同期完了後、イベント情報を取得のみ
                let stampManager = StampManager.shared
                await stampManager.fetchCurrentEvent()
                
                print("✅ ContentView: Data sync and event fetch completed")
                // バナー表示チェックはHomeViewで行う
            }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            // ✅ ログアウト時の処理のみ
            if !newValue && oldValue {
                print("🔄 ログアウト - 状態リセット")
                appLoader.reset()
            }
        }
    }
}

#Preview {
    ContentView()
}
