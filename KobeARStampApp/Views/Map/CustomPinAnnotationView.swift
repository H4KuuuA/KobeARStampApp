import SwiftUI

struct SpotAnnotationView: View {
    let spot: Spot
    var size: CGFloat = 40
    var pinColorHex: String = "#0000FF"
    
    // アニメーション用のState
    @State private var isSelected: Bool = false
    @State private var animationType: AnimationType = .none
    @State private var showPulse: Bool = false
    @State private var isInProximity: Bool = false
    
    // アニメーションタイプを定義
    enum AnimationType {
        case none
        case tap      // タップ時: 拡大のみ
        case proximity // 接近時: 波形
    }
    
    // pinColorHex を Color に変換。失敗したら青
    var pinColor: Color {
        Color(hex: pinColorHex) ?? .blue
    }
    
    var body: some View {
        VStack(spacing:0) {
            ZStack {
                // メインのピン画像
                Image("Annotation")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(pinColor)
                    .scaleEffect(isSelected && animationType == .tap ? 1.3 : 1.0)
                
                // 画像部分
                spotImageView
            }
            // View+Animations.swiftのpulseEffectを使用
            .pulseEffect(
                isActive: showPulse,
                color: pinColor,
                baseSize: size * 0.8,
                duration: 1.5
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotDeselected)) { _ in
            // 選択を解除
            if isInProximity {
                // エリア内の場合：選択状態を解除してエフェクトを再開
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isSelected = false
                    animationType = .proximity
                }
                // エフェクトを再開
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPulse = true
                }
            } else {
                // エリア外の場合：完全に解除
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    isSelected = false
                    animationType = .none
                    showPulse = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotTapped)) { notification in
            if let tappedSpot = notification.object as? Spot {
                if tappedSpot.id == spot.id {
                    // 自分がタップされた場合
                    if isInProximity {
                        // エリア内の場合：パルスエフェクトを停止して選択状態に
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            isSelected = true
                            animationType = .tap
                            showPulse = false
                        }
                    } else {
                        // エリア外の場合：拡大アニメーションのみ
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            isSelected = true
                            animationType = .tap
                            showPulse = false
                        }
                    }
                } else {
                    // 他のスポットがタップされた場合：自分の選択を解除
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        isSelected = false
                        animationType = .none
                        showPulse = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .spotProximityEntered)) { notification in
            if let enteredSpot = notification.object as? Spot {
                if enteredSpot.id == spot.id {
                    // エリア内フラグを立てる
                    isInProximity = true
                    // 自分に接近した場合：波形エフェクト
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        animationType = .proximity
                    }
                    // パルスエフェクトを開始
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showPulse = true
                    }
                }
            }
        }
    }
    
    // MARK: - Spot Image View
    
    @ViewBuilder
    private var spotImageView: some View {
        if let imageURL = spot.imageURL {
            // 外部URLから画像を取得（ローカル画像をフォールバックとして表示）
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    // 読み込み中: ローカル画像を表示
                    localImageView
                    
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: size * 0.8, height: size * 0.8)
                        .clipShape(Circle())
                        .imageBorder(isSelected: isSelected)
                        .offset(y: -size * 0.05)
                        .scaleEffect(isSelected && animationType == .tap ? 1.3 : 1.0)
                    
                case .failure:
                    // 取得失敗: ローカル画像を表示
                    localImageView
                    
                @unknown default:
                    localImageView
                }
            }
        } else {
            // URLがない場合: ローカル画像を使用
            localImageView
        }
    }
    
    @ViewBuilder
    private var localImageView: some View {
        if let localImage = UIImage(named: spot.placeholderImageName) {
            Image(uiImage: localImage)
                .resizable()
                .scaledToFill()
                .frame(width: size * 0.8, height: size * 0.8)
                .clipShape(Circle())
                .imageBorder(isSelected: isSelected)
                .offset(y: -size * 0.05)
                .scaleEffect(isSelected && animationType == .tap ? 1.3 : 1.0)
        } else {
            placeholderCircleImage
        }
    }
    
    @ViewBuilder
    private var placeholderCircleImage: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.8, height: size * 0.8)
                .shadow(color: isSelected ? .gray.opacity(0.5) : .clear, radius: 4)
            
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.5, height: size * 0.5)
                .foregroundColor(.gray)
        }
        .offset(y: -size * 0.05)
        .scaleEffect(isSelected && animationType == .tap ? 1.3 : 1.0)
    }
}

// MARK: - Image Border Modifier
extension View {
    func imageBorder(isSelected: Bool) -> some View {
        self.overlay(
            Circle()
                .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
        )
    }
}

#Preview {
    SpotAnnotationView(
        spot: Spot.testSpot,
        size: 96,
        pinColorHex: "#FF0000"
    )
}
