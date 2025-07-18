//
//  CustomAnnotaitonView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/14.
//

import SwiftUI

/// - Parameters:
///   - pin: 表示するカスタムピン情報（`CustomPin`型）
///   - size: ピン本体のサイズ（幅・高さ）
///   - pinColor: ピンの背景色（`Color`型）、`Annotation`画像のテンプレートカラーに反映されます。デフォルトは青色
struct CustomAnnotaitonView: View {
    let pin : CustomPin
    var size: CGFloat = 40
    var pinColorHex: String = "#0000FF"
    
    // アニメーション用のState
    @State private var isSelected: Bool = false
    @State private var showPulseEffect: Bool = false
    @State private var sparkleOpacity: Double = 0.0
    
    // pinColorHex を Color に変換。失敗したら青
    var pinColor: Color {
        Color(hex: pinColorHex) ?? .blue
    }
    
    var body: some View {
        VStack(spacing:0) {
            ZStack {
                // パルスエフェクト用の背景円
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(pinColor.opacity(0.4), lineWidth: 2)
                        .frame(width: size * 1.5, height: size * 1.5)
                        .scaleEffect(showPulseEffect ? 2.0 + Double(index) * 0.3 : 1.0)
                        .opacity(showPulseEffect ? 0.8 : 0.0)
                        .animation(.easeOut(duration: 0.8).delay(Double(index) * 0.1), value: showPulseEffect)
                }
                
                // グロー効果
                Circle()
                    .fill(pinColor.opacity(0.3))
                    .frame(width: size * 1.8, height: size * 1.8)
                    .blur(radius: 8)
                    .opacity(isSelected ? 0.8 : 0.0)
                    .animation(.easeInOut(duration: 0.3), value: isSelected)
                
                // メインのピン画像
                Image("Annotation")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(pinColor)
                    .scaleEffect(isSelected ? 1.3 : 1.0)
                    .shadow(color: isSelected ? pinColor.opacity(0.6) : .clear, radius: 8, x: 0, y: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSelected)
                
                // 画像部分
                AsyncImage(url: pin.imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: size * 0.6, height: size * 0.6)

                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: size * 0.6, height: size * 0.6)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(isSelected ? Color.white : Color.white, lineWidth: isSelected ? 3 : 2)
                                    .shadow(color: isSelected ? .white.opacity(0.8) : .clear, radius: 4)
                            )
                            .offset(y: -size * 0.1)
                            .scaleEffect(isSelected ? 1.3 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSelected)

                    case .failure:
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: size * 0.8, height: size * 0.8)
                                .shadow(color: isSelected ? .gray.opacity(0.5) : .clear, radius: 4)

                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: size * 0.6, height: size * 0.6)
                                .foregroundColor(.gray)
                        }
                        .offset(y: -size * 0.05)
                        .scaleEffect(isSelected ? 1.3 : 1.0)
                        .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSelected)
                        
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .customPinDeselected)) { _ in
            // 他の場所がタップされたときに選択を解除
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isSelected = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .customPinTapped)) { notification in
            if let tappedPin = notification.object as? CustomPin {
                if tappedPin.id == pin.id {
                    // 自分がタップされた場合：選択状態にしてエフェクトを開始
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isSelected = true
                    }
                    
                    // パルスエフェクト開始
                    showPulseEffect = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showPulseEffect = false
                    }
                    
                    withAnimation(.easeInOut(duration: 0.6)) {
                        sparkleOpacity = 0.0
                    }
                } else {
                    // 他のピンがタップされた場合：自分の選択を解除
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isSelected = false
                    }
                }
            }
        }
    }
}

#Preview {
    CustomAnnotaitonView(pin: mockPins[0], size: 96, pinColorHex: "#FF0000")
}
