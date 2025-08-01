//
//  AnimationSideBar.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/08/01.
//

import SwiftUI

struct AnimationSideBar<Content: View,MenuView: View, Background: View>: View {
    
    // 設定項目
    var rotatesWhenExpands: Bool = true
    var disablesInteraction: Bool = true
    var sideMenuWidth: CGFloat = 200
    var cornerRadius: CGFloat = 25
    @Binding var showMenu: Bool
    
    @ViewBuilder var content: (UIEdgeInsets) -> Content
    @ViewBuilder var menuView: (UIEdgeInsets) -> MenuView
    @ViewBuilder var background: Background
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            let safeArea = (UIApplication.shared.connectedScenes.first as?
                            UIWindowScene)?.keyWindow?.safeAreaInsets ?? .zero
            
            HStack(spacing: 0) {
                GeometryReader {_ in
                    menuView(safeArea)
                }
                .frame(width: sideMenuWidth)
                GeometryReader {_ in
                    content(safeArea)
                }
                .frame(width: size.width)
            }
            .frame(width: size.width + sideMenuWidth, height: size.height)
            .offset(x: -sideMenuWidth)
        }
        .ignoresSafeArea()
    }
}

#Preview {
    SidebarContainerView()
}
