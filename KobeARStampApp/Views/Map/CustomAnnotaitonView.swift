import SwiftUI

struct CustomAnnotaitonView: View {
    let pin : CustomPin
    var size: CGFloat = 40
    var pinColorHex: String = "#0000FF"
    
    // アニメーション用のState
    @State private var isSelected: Bool = false
    @State private var sparkleOpacity: Double = 0.0
    
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
                    .selectionEffect(isSelected: isSelected, color: pinColor)
                
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
                            .imageBorder(isSelected: isSelected)
                            .offset(y: -size * 0.1)
                            .selectionEffect(isSelected: isSelected, color: pinColor)

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
                        .selectionEffect(isSelected: isSelected, color: pinColor)
                        
                    @unknown default:
                        EmptyView()
                    }
                }
            }
            .pulseEffect(isActive: isSelected, color: pinColor, baseSize: size)
            .glowEffect(isActive: isSelected, color: pinColor, size: size * 1.8)
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
