//
//  AppLoaderViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/26.
//

import SwiftUI

@MainActor
class AppLoaderViewModel: ObservableObject {
    @Published var isLoading = true
    
    private var minLoadingTime: TimeInterval = 1.5
    
    func startLoading() async {
        try? await Task.sleep(nanoseconds: UInt64(minLoadingTime * 1_000_000_000))
        
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isLoading = false
        }
    }
}
