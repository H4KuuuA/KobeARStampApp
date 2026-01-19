//
//  LoadingView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/17.
//

import SwiftUI

struct LoadingView: View {
    @ObservedObject var appLoader: AppLoaderViewModel
    @ObservedObject var arModelManager = ARModelManager.shared
    
    @State private var currentSlide = 0
    @State private var slideTimer: Timer?
    
    // チュートリアルスライドのデータ
    private let slides: [TutorialSlide] = [
        TutorialSlide(
            stepNumber: 1,
            icon: "iphone",
            title: "アプリを開く",
            description: "アプリを起動すると、まずカメラの使用許可を求められることがあります。案内に従って「許可」してください。"
        ),
        TutorialSlide(
            stepNumber: 2,
            icon: "location.fill",
            title: "位置情報の許可",
            description: "まち歩き中に現在地を確認したり、スポット付近に来たことを認識するために必要です。「アプリの使用中は許可」を選んでください。"
        ),
        TutorialSlide(
            stepNumber: 3,
            icon: "map",
            title: "マップを見る",
            description: "ホーム画面には地図が表示されます。自分の位置や、スポットのおおよその場所が確認できます。"
        ),
        TutorialSlide(
            stepNumber: 4,
            icon: "figure.walk",
            title: "スポットの近くに行く",
            description: "スポットの近くに行くと、アプリが自動で反応します。画面の案内に従ってください。"
        ),
        TutorialSlide(
            stepNumber: 5,
            icon: "camera.fill",
            title: "ARを楽しむ",
            description: "スポットについたら、カメラを向けてください。特別なARコンテンツが表示されます。"
        ),
        TutorialSlide(
            stepNumber: 6,
            icon: "checkmark.circle.fill",
            title: "終わり方",
            description: "アプリはいつでも閉じて大丈夫です。位置情報やデータは匿名で扱われ、個人が特定されることはありません。"
        )
    ]
    
    var body: some View {
        ZStack {
            // 背景（ライトモード固定のため白)
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // ロゴエリア
                VStack(spacing: 16) {
                    Image("Splash")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 90)
                        .padding(.leading, 42)
                    
                }
                .padding(.top, 60)
                .padding(.bottom, 16)
                
                // スライドエリア
                TabView(selection: $currentSlide) {
                    ForEach(slides.indices, id: \.self) { index in
                        SlideView(slide: slides[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: 400)
                
                // ページインジケーター
                HStack(spacing: 8) {
                    ForEach(slides.indices, id: \.self) { index in
                        Circle()
                            .fill(currentSlide == index ? Color("DarkBlue") : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut(duration: 0.3), value: currentSlide)
                    }
                }
                .padding(.bottom, 10)
                
                Spacer()
                
                // プログレスバーエリア
                VStack(spacing: 12) {
                    // ステータスメッセージ
                    Text(appLoader.loadingMessage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // プログレスバー
                    VStack(spacing: 8) {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // 背景
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.2))
                                    .frame(height: 20)
                                
                                // 進捗（グラデーション）
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color("LightBlue"), Color("DarkBlue")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width * arModelManager.progress,
                                        height: 20
                                    )
                            }
                        }
                        .frame(height: 20)
                        .animation(.linear(duration: 0.2), value: arModelManager.progress)
                        
                        // パーセンテージ（ゲージと同じアニメーション）
                        Text("\(Int(arModelManager.progress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color("DarkBlue"))
                            .animation(.linear(duration: 0.2), value: arModelManager.progress)
                    }
                    .padding(.horizontal, 40)
                    
                    // エラーメッセージ（あれば表示）
                    if let error = appLoader.errorMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .preferredColorScheme(.light)  // ✅ ライトモード固定
        .onAppear {
            startSlideTimer()
        }
        .onDisappear {
            stopSlideTimer()
        }
    }
    
    // MARK: - Timer Control
    
    private func startSlideTimer() {
        slideTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentSlide = (currentSlide + 1) % slides.count
            }
        }
    }
    
    private func stopSlideTimer() {
        slideTimer?.invalidate()
        slideTimer = nil
    }
}

// MARK: - Slide View

struct SlideView: View {
    let slide: TutorialSlide
    
    var body: some View {
        VStack(spacing: 20) {
            // ステップ番号 + アイコン
            ZStack {
                Circle()
                    .fill(Color("DarkBlue"))
                    .frame(width: 80, height: 80)
                
                VStack(spacing: 4) {
                    Image(systemName: slide.icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text("Step \(slide.stepNumber)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 8)
            
            // タイトル
            Text(slide.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // 説明文
            Text(slide.description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)  // ✅ ライトモード固定のため白背景
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal, 20)
    }
}

// MARK: - Tutorial Slide Model

struct TutorialSlide {
    let stepNumber: Int
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview {
    LoadingView(appLoader: AppLoaderViewModel())
}
