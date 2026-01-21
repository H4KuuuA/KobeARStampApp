//
//  CameraGuideView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2026/01/20.
//

import SwiftUI

struct CameraGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentStep = 0
    
    private let steps: [GuideStep] = [
        GuideStep(
            icon: "location.fill",
            title: "スポットに近づく",
            description: "スタンプポイントから25m以内に近づくと「撮影可能エリア」と表示されます。",
            tips: [
                "マップでスポットの位置を確認",
                "近くに来たら画面上部をチェック"
            ]
        ),
        GuideStep(
            icon: "arkit",
            title: "平面にモデルを配置",
            description: "ARカメラを起動して、床や地面などの平らな場所にキャラクターを配置しましょう。",
            tips: [
                "画面をゆっくり動かして平面を検出",
                "白い点が表示されたらタップ"
            ]
        ),
        GuideStep(
            icon: "sun.max.fill",
            title: "明るい場所で撮影",
            description: "キャラクターがきれいに映るように、なるべく屋外の明るい場所で撮影してください。",
            tips: [
                "屋外での撮影を推奨",
                "逆光を避けると◎"
            ]
        ),
        GuideStep(
            icon: "camera.viewfinder",
            title: "キャラクター全体を撮る",
            description: "キャラクターが画面に収まるように調整して、シャッターボタンを押しましょう。",
            tips: [
                "モデル全体が見えるように",
                "手ブレに注意"
            ]
        ),
        GuideStep(
            icon: "checkmark.seal.fill",
            title: "スタンプゲット！",
            description: "撮影が完了すると、自動的にスタンプが保存されます。全スポット制覇を目指そう！",
            tips: [
                "スタンプカードで進捗確認",
                "お気に入りの写真をシェア"
            ]
        )
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            dragIndicator
            headerView
            stepContentView
            bottomControlsView
        }
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Drag Indicator
    
    private var dragIndicator: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.gray.opacity(0.3))
            .frame(width: 40, height: 5)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("使い方ガイド")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DarkBlue"))
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(.horizontal, 24)
            
            pageIndicatorView
        }
        .padding(.bottom, 24)
    }
    
    // MARK: - Page Indicator
    
    private var pageIndicatorView: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? Color("DarkBlue") : Color.gray.opacity(0.3))
                    .frame(width: index == currentStep ? 28 : 8, height: 8)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step Content View
    
    private var stepContentView: some View {
        TabView(selection: $currentStep) {
            ForEach(0..<steps.count, id: \.self) { index in
                ScrollView {
                    stepView(steps[index])
                        .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .animation(.easeInOut, value: currentStep)
    }
    
    // MARK: - Step View
    
    @ViewBuilder
    private func stepView(_ step: GuideStep) -> some View {
        VStack(spacing: 24) {
            iconView(step.icon)
            
            VStack(spacing: 12) {
                Text(step.title)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DarkBlue"))
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 8)
            }
            
            tipsCard(step.tips)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
    }
    
    // MARK: - Icon View
    
    @ViewBuilder
    private func iconView(_ iconName: String) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color("DarkBlue").opacity(0.1),
                            Color("DarkBlue").opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
            
            Circle()
                .fill(Color("DarkBlue"))
                .frame(width: 100, height: 100)
            
            Image(systemName: iconName)
                .font(.system(size: 44, weight: .semibold))
                .foregroundColor(.white)
        }
        .shadow(color: Color("DarkBlue").opacity(0.2), radius: 16, x: 0, y: 8)
    }
    
    // MARK: - Tips Card
    
    @ViewBuilder
    private func tipsCard(_ tips: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                
                Text("ポイント")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color("DarkBlue"))
            }
            
            VStack(spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(Color("DarkBlue"))
                            .padding(.top, 2)
                        
                        Text(tip)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    // MARK: - Bottom Controls
    
    private var bottomControlsView: some View {
        VStack(spacing: 12) {
            if currentStep < steps.count - 1 {
                HStack(spacing: 12) {
                    Button(action: {
                        dismiss()
                    }) {
                        Text("スキップ")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.systemGray6))
                            )
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            currentStep += 1
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("次へ")
                                .font(.system(size: 16, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color("DarkBlue"))
                        )
                    }
                }
                .padding(.horizontal, 24)
            } else {
                Button(action: {
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Text("始める")
                            .font(.system(size: 17, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color("DarkBlue"),
                                        Color("DarkBlue").opacity(0.85)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: Color("DarkBlue").opacity(0.4), radius: 12, x: 0, y: 6)
                    )
                }
                .padding(.horizontal, 24)
            }
        }
        .padding(.top, 20)
        .padding(.bottom, 32)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Guide Step Model

struct GuideStep {
    let icon: String
    let title: String
    let description: String
    let tips: [String]
}

#Preview {
    CameraGuideView()
        .presentationDetents([.large])
}
