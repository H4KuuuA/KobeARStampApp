//
//  SplashView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/26.
//

import SwiftUI

struct SplashView: View {
    @ObservedObject var appLoader: AppLoaderViewModel
    @State private var logoScale: CGFloat = 0.5
    @State private var logoOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // メインロゴ
                Image("Splash")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 186, height: 186)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    .offset(x: 15)
                
                Spacer()
                
                // ローディングインジケーター
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                    .scaleEffect(1.2)
                    .opacity(logoOpacity)
                    .padding(.bottom, 80)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 1.2)) {
                    logoScale = 1.0
                    logoOpacity = 1.0
                }
                
                Task {
                    await appLoader.startLoading()
                }
            }
        }
        .preferredColorScheme(.light)
    }
}

#Preview {
    SplashView(appLoader: AppLoaderViewModel())
}
