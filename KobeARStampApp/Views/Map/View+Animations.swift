//
//  View+Animations.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/18.
//

// View+Animations.swift

import SwiftUI

// MARK: - アニメーション用 View 拡張
extension View {
    /// パルスエフェクト用のアニメーション（修正版）
    func pulseEffect(isActive: Bool, color: Color, baseSize: CGFloat, duration: Double = 0.8) -> some View {
        ZStack {
            self
            
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(color.opacity(0.4), lineWidth: 2)
                    .frame(width: baseSize * 1.5, height: baseSize * 1.5)
                    .scaleEffect(isActive ? 2.0 + Double(index) * 0.3 : 1.0)
                    .opacity(isActive ? 0.8 - Double(index) * 0.2 : 0.0)
                    .animation(
                        isActive ?
                        .easeOut(duration: duration).delay(Double(index) * 0.1).repeatForever(autoreverses: false) :
                        .easeOut(duration: 0.3),
                        value: isActive
                    )
            }
        }
    }

    /// グロー効果のアニメーション
    func glowEffect(isActive: Bool, color: Color, size: CGFloat, intensity: Double = 0.8) -> some View {
        ZStack {
            self
            
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: size, height: size)
                .blur(radius: 8)
                .opacity(isActive ? intensity : 0.0)
                .animation(.easeInOut(duration: 0.3), value: isActive)
        }
    }

    /// 選択時のスケール・シャドウ効果
    func selectionEffect(isSelected: Bool, color: Color, scale: CGFloat = 1.3) -> some View {
        self
            .scaleEffect(isSelected ? scale : 1.0)
            .shadow(color: isSelected ? color.opacity(0.6) : .clear, radius: 8, x: 0, y: 4)
            .animation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0), value: isSelected)
    }

    /// 画像の境界線効果
    func imageBorder(isSelected: Bool, normalWidth: CGFloat = 2, selectedWidth: CGFloat = 3) -> some View {
        self.overlay(
            Circle()
                .stroke(Color.white, lineWidth: isSelected ? selectedWidth : normalWidth)
                .shadow(color: isSelected ? .white.opacity(0.8) : .clear, radius: 4)
        )
    }
}
