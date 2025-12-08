//
//  HomeView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/02.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        MainTabView()
            .preferredColorScheme(.light)  // 常にライトモードに固定
    }
}

#Preview {
    ContentView()
}
