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
    
    /// Viewの設定項目
    @GestureState private var isDragging: Bool = false
    @State private var offsetX: CGFloat = 0
    @State private var lastOffsetX: CGFloat = 0
    
    /// サイドバーが操作されている時にコンテントビューを暗くする
    @State private var progress: CGFloat = 0
    
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
                /// メニューの幅を超える領域での操作を制限する
                .contentShape(.rect)
                
                GeometryReader {_ in
                    content(safeArea)
                }
                .frame(width: size.width)
            }
            .frame(width: size.width + sideMenuWidth, height: size.height)
            .offset(x: -sideMenuWidth)
            .offset(x: offsetX)
            .contentShape(.rect)
            .gesture(dragGesture)
        }
        .ignoresSafeArea()
        .onChange(of: showMenu, initial: true) { oldValue, newValue in
            withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                if newValue {
                    showSideBar()
                }else {
                    reset()
                }
            }
        }
    }
    
    /// ドラッグジェスチャー （使わないかも)
    var dragGesture: some Gesture {
        DragGesture()
            .updating($isDragging) {_, out, _ in
                out = true
            }.onChanged { value in
                _ = isDragging ? max(min(value.translation.width + lastOffsetX, sideMenuWidth), 0) : 0
            }.onEnded { value in
                withAnimation(.snappy(duration: 0.3, extraBounce: 0)) {
                    let velocityX = value.velocity.width / 8
                    let total = velocityX + offsetX
                        showSideBar()
                    if total > (sideMenuWidth * 0.5) {
                        
                    } else {
                        reset()
                    }
                }
            }
    }
    /// Show's Side Bar
    func showSideBar() {
        offsetX = sideMenuWidth
        lastOffsetX = offsetX
        showMenu = true
    }
    
    /// Reset's to it's Initial State
    func reset() {
        offsetX = 0
        lastOffsetX = 0
        showMenu = false
    }
}

#Preview {
    SidebarContainerView()
}
