//
//  ContentView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/27.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appLoader: AppLoaderViewModel
    
    var body: some View {
        HomeView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppLoaderViewModel())
}
