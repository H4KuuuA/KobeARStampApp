//
//  ClearCelebrationView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2026/01/21.
//

import SwiftUI

// MARK: - メインのクリア画面ビュー
struct ClearCelebrationView: View {
    @State private var showContent = false
    @State private var showConfetti = false
    @State private var scale: CGFloat = 0.3
    @State private var rotation: Double = -180
    
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // 背景グラデーション
            backgroundGradient
            
            // 紙吹雪レイヤー
            if showConfetti {
                ConfettiAnimationView()
            }
            
            // スパークルエフェクト
            if showContent {
                SparkleView()
            }
            
            // メインコンテンツ
            VStack(spacing: 40) {
                Spacer()
                
                // クリアマークとリングエフェクト
                ZStack {
                    if showContent {
                        PulsingRingView()
                    }
                    
                    clearBadge
                }
                
                // テキストコンテンツ
                textContent
                
                Spacer()
                
                // アクションボタン
                dismissButton
            }
            .padding()
        }
        .onAppear {
            startAnimation()
        }
    }
    
    // MARK: - サブビュー
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color("DarkBlue"),
                Color("DarkBlue").opacity(0.8),
                Color("DarkBlue")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var clearBadge: some View {
        ZStack {
            // 背景円
            Circle()
                .fill(Color.white)
                .frame(width: 180, height: 180)
                .shadow(color: Color("LightBlue").opacity(0.5), radius: 30, x: 0, y: 10)
            
            // 内側の青いサークル
            Circle()
                .stroke(Color("LightBlue"), lineWidth: 4)
                .frame(width: 160, height: 160)
            
            // CLEARテキスト
            VStack(spacing: 4) {
                Text("")
                    .font(.system(size: 50))
                
                Text("CLEAR!")
                    .font(.system(size: 32, weight: .black, design: .default))
                    .foregroundColor(Color("DarkBlue"))
            }
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
    }
    
    private var textContent: some View {
        VStack(spacing: 16) {
            Text("スタンプラリー完走!")
                .font(.system(size: 28, weight: .bold, design: .default))
                .foregroundColor(.white)
                .opacity(showContent ? 1 : 0)
            
            Text("おめでとうございます")
                .font(.system(size: 18, weight: .medium, design: .default))
                .foregroundColor(.white.opacity(0.9))
                .opacity(showContent ? 1 : 0)
        }
    }
    
    private var dismissButton: some View {
        Button(action: onDismiss) {
            Text("完了")
                .font(.system(size: 18, weight: .semibold, design: .default))
                .foregroundColor(Color("DarkBlue"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color("LightBlue").opacity(0.5), radius: 15, x: 0, y: 5)
        }
        .opacity(showContent ? 1 : 0)
        .padding(.horizontal, 40)
        .padding(.bottom, 20)
    }
    
    // MARK: - アニメーション制御
    
    private func startAnimation() {
        // クリアバッジのアニメーション
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6, blendDuration: 0)) {
            scale = 1.0
            rotation = 0
        }
        
        // コンテンツの表示
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showContent = true
        }
        
        // 紙吹雪の開始
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            showConfetti = true
        }
    }
}

// MARK: - 紙吹雪パーティクル
struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let shape: ParticleShape
    let startX: CGFloat
    let startY: CGFloat
    var currentY: CGFloat
    var rotation: Double
    var velocity: CGFloat
    
    enum ParticleShape {
        case circle
        case square
        case triangle
        case rectangle
    }
    
    static func random(screenWidth: CGFloat) -> ConfettiParticle {
        let colors: [Color] = [
            Color.white,
            Color.white.opacity(0.9),
            Color("LightBlue").opacity(0.8),
            Color.white.opacity(0.7),
            Color("LightBlue").opacity(0.6)
        ]
        
        let shapes: [ParticleShape] = [.circle, .square, .triangle, .rectangle]
        
        return ConfettiParticle(
            color: colors.randomElement()!,
            shape: shapes.randomElement()!,
            startX: CGFloat.random(in: 0...screenWidth),
            startY: -20,
            currentY: -20,
            rotation: Double.random(in: 0...360),
            velocity: CGFloat.random(in: 2...5)
        )
    }
}

// MARK: - 紙吹雪アニメーションビュー
struct ConfettiAnimationView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ParticleView(particle: particle)
                        .position(x: particle.startX, y: particle.currentY)
                }
            }
            .onAppear {
                startConfetti(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startConfetti(screenWidth: CGFloat, screenHeight: CGFloat) {
        // 初期パーティクル生成
        for _ in 0..<30 {
            particles.append(ConfettiParticle.random(screenWidth: screenWidth))
        }
        
        // アニメーションタイマー
        timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { _ in
            updateParticles(screenWidth: screenWidth, screenHeight: screenHeight)
        }
    }
    
    private func updateParticles(screenWidth: CGFloat, screenHeight: CGFloat) {
        for index in particles.indices {
            particles[index].currentY += particles[index].velocity
            particles[index].rotation += 5
            
            // 画面外に出たら削除
            if particles[index].currentY > screenHeight + 20 {
                particles.remove(at: index)
                // 新しいパーティクルを追加
                if particles.count < 50 {
                    particles.append(ConfettiParticle.random(screenWidth: screenWidth))
                }
                break
            }
        }
    }
}

// MARK: - パーティクルの形状ビュー
struct ParticleView: View {
    let particle: ConfettiParticle
    
    var body: some View {
        Group {
            switch particle.shape {
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
            case .square:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: 8, height: 8)
            case .triangle:
                Triangle()
                    .fill(particle.color)
                    .frame(width: 10, height: 10)
            case .rectangle:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: 12, height: 6)
            }
        }
        .rotationEffect(.degrees(particle.rotation))
    }
}

// MARK: - 三角形シェイプ
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - スパークルエフェクト
struct SparkleView: View {
    @State private var sparkles: [SparkleParticle] = []
    @State private var timer: Timer?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(sparkles) { sparkle in
                    Circle()
                        .fill(Color.white)
                        .frame(width: sparkle.size, height: sparkle.size)
                        .opacity(sparkle.opacity)
                        .position(x: sparkle.x, y: sparkle.y)
                        .blur(radius: 2)
                }
            }
            .onAppear {
                startSparkles(screenWidth: geometry.size.width, screenHeight: geometry.size.height)
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    private func startSparkles(screenWidth: CGFloat, screenHeight: CGFloat) {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if sparkles.count < 20 {
                sparkles.append(SparkleParticle.random(
                    screenWidth: screenWidth,
                    screenHeight: screenHeight
                ))
            }
            
            updateSparkles()
        }
    }
    
    private func updateSparkles() {
        sparkles = sparkles.map { sparkle in
            var updated = sparkle
            updated.opacity -= 0.02
            updated.size += 0.1
            return updated
        }.filter { $0.opacity > 0 }
    }
}

// MARK: - スパークルパーティクル
struct SparkleParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    var size: CGFloat
    var opacity: Double
    
    static func random(screenWidth: CGFloat, screenHeight: CGFloat) -> SparkleParticle {
        SparkleParticle(
            x: CGFloat.random(in: 0...screenWidth),
            y: CGFloat.random(in: 0...screenHeight),
            size: CGFloat.random(in: 2...6),
            opacity: Double.random(in: 0.5...1.0)
        )
    }
}

// MARK: - パルスリングエフェクト
struct PulsingRingView: View {
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        ZStack {
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        Color("LightBlue").opacity(0.4),
                        lineWidth: 3
                    )
                    .frame(width: 180, height: 180)
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .animation(
                        Animation.easeOut(duration: 1.5)
                            .repeatForever(autoreverses: false)
                            .delay(Double(index) * 0.3),
                        value: scale
                    )
            }
        }
        .onAppear {
            scale = 1.6
            opacity = 0
        }
    }
}

// MARK: - プレビュー
struct ClearCelebrationView_Previews: PreviewProvider {
    static var previews: some View {
        ClearCelebrationView(onDismiss: {
            print("Dismissed")
        })
    }
}
