//
//  StampProgressBar.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/08/01.
//

import SwiftUI

struct StampProgressBar: View {
    @ObservedObject var stampManager: StampManager
    let size: CGFloat
    let showPercentage: Bool
    
    // アニメーション用の状態変数
    @State private var animatedProgress: CGFloat = 0
    @State private var animatedSize: CGFloat = 40
    
    // 進捗の割合を計算
    private var progressRatio: CGFloat {
        guard stampManager.totalSpotCount > 0 else { return 0 }
        return CGFloat(stampManager.acquiredStampCount) / CGFloat(stampManager.totalSpotCount)
    }
    
    var body: some View {
        ZStack {
            // 背景の円
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: animatedSize * 0.2)
                .frame(width: animatedSize, height: animatedSize)
            
            // プログレス表示の円
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("DarkBlue"),
                            Color("LightBlue")
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: animatedSize * 0.2, lineCap: .round)
                )
                .frame(width: animatedSize, height: animatedSize)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.blue.opacity(0.3), radius: animatedSize * 0.05, x: 0, y: 0)
            
            // パーセント表示
            if showPercentage {
                Text("\(Int(progressRatio * 100))%")
                    .font(.system(size: animatedSize * 0.18, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DarkBlue"))
            }
        }
        // size の変更に対応
        .onChange(of: size) { _, newSize in
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.3)) {
                animatedSize = newSize
            }
        }
        // progress の変更に対応
        .onChange(of: progressRatio) { _, newRatio in
            withAnimation(.easeInOut(duration: 0.8)) {
                animatedProgress = newRatio
            }
        }
        .onAppear {
            animatedProgress = progressRatio
            animatedSize = size
        }
    }
}

struct StampDemoView: View {
    @StateObject private var stampManager = StampManager()
    @State private var isExpanded = false
    @State private var eventName = "みんなで!アート探検 in HAT神戸"
    
    // カスタムアニメーション設定
    private var expansionAnimation: Animation {
        .spring(response: 0.8, dampingFraction: 0.75, blendDuration: 0.3)
    }
    
    private var contentAnimation: Animation {
        .easeInOut(duration: 0.6).delay(isExpanded ? 0.2 : 0)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            ZStack {
                // 背景のRectangle
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: isExpanded ? 200 : 75)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.05)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .animation(expansionAnimation, value: isExpanded)
                
                HStack(alignment: .center) {
                    // ✅ プログレスバーは常に1つ
                    HStack {
                        StampProgressBar(
                            stampManager: stampManager,
                            size: isExpanded ? 100 : 40,
                            showPercentage: isExpanded
                        )
                        Spacer()
                    }
                    .frame(width: isExpanded ? 120 : 60)
                    
                    if isExpanded {
                        // 拡大時のテキスト表示
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 10) {
                                Image(systemName: "location.fill")
                                    .foregroundColor(Color("DarkBlue"))
                                    .font(.system(size: 14, weight: .medium))
                                
                                Text(eventName)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    .multilineTextAlignment(.leading)
                                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.seal.fill")
                                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.6))
                                        .font(.system(size: 14, weight: .bold))
                                    
                                    Text("PROGRESS")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                        .foregroundColor(Color(red: 0.0, green: 0.2, blue: 0.6).opacity(0.7))
                                        .tracking(1.2)
                                }
                                VStack(spacing: 0) {
                                    Text("取得スタンプ数: ")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    HStack(spacing: 0) {
                                        Text("\(stampManager.acquiredStampCount)")
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundColor(Color("DarkBlue"))
                                            .contentTransition(.numericText())
                                        
                                        Text("/\(stampManager.totalSpotCount)")
                                            .font(.system(size: 40, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                    }
                                    .animation(.spring(), value: stampManager.acquiredStampCount)
                                }
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                                .padding(.leading, 2)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                        .transition(.opacity.combined(with: .scale))
                        .animation(contentAnimation, value: isExpanded)
                    } else {
                        // 縮小時のテキスト表示
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundColor(Color("DarkBlue"))
                                    .font(.system(size: 10, weight: .bold))
                                
                                Text("PROGRESS")
                                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color("DarkBlue"))
                                    .tracking(0.8)
                            }
                            
                            HStack(spacing: 0) {
                                Text("取得スタンプ数: ")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                                
                                Text("\(stampManager.acquiredStampCount)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("DarkBlue"))
                                    .contentTransition(.numericText())
                                
                                Text("/\(stampManager.totalSpotCount)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            }
                            .animation(.spring(), value: stampManager.acquiredStampCount)
                            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12)
                        .transition(.opacity.combined(with: .scale))
                        .animation(contentAnimation, value: isExpanded)
                    }
                }
                .padding(.horizontal, 16)
            }
            .onTapGesture {
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                withAnimation(expansionAnimation) {
                    isExpanded.toggle()
                }
            }
            
//            // デバッグ用ボタン
//            #if DEBUG
//            HStack {
//                Button("スタンプ +1") {
//                    stampManager.debugAcquireFirstStamp()
//                }
//                .padding()
//                .background(Color.blue)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//                
//                Button("リセット") {
//                    stampManager.resetAllStamps()
//                }
//                .padding()
//                .background(Color.red)
//                .foregroundColor(.white)
//                .cornerRadius(8)
//            }
//            
        }
        .padding()
    }
}

struct StampProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        StampDemoView()
    }
}
