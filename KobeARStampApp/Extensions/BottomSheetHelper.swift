//
//  BottomSheetHelper.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/02.
//

import SwiftUI

extension View {
    @ViewBuilder
    /// デフォルトのsheetの高さは49
    func BottomMaskSheet(_ height: CGFloat=49) -> some View {
        self
    }
}
// Helps
fileprivate struct SheetRootViewFinder: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            
        }
    }
    
    func makeUIView(context: Context) -> UIView {
        return .init()
    }
    class Coordinator: NSObject {
        // ステータス
        var isMasked: Bool = false
    }
}

#Preview {
    ContentView()
}
