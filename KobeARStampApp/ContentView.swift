//
//  ContentView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/27.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appLoader: AppLoaderViewModel
    @AppStorage("hasCompletedInitialSetup") private var hasCompletedInitialSetup = false
    
    var body: some View {
        Group {
            if appLoader.isLoading {
                // ローディング画面（既存のものがあればそれを使用）
                ProgressView()
            } else {
                if hasCompletedInitialSetup {
                    HomeView()
                } else {
                    InitialLoginView(hasCompletedInitialSetup: $hasCompletedInitialSetup)
                }
            }
        }
        .task {
            await appLoader.startLoading()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLoaderViewModel())
}
