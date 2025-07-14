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
    var pinColor: Color = .blue
    
    var body: some View {
        VStack(spacing:0) {
            ZStack {
                Image("Annotation")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .foregroundColor(pinColor)
                
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
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .offset(y: -size * 0.1)

                    case .failure:
                        ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: size * 0.8, height: size * 0.8)

                                    Image(systemName: "photo")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: size * 0.6, height: size * 0.6)
                                        .foregroundColor(.gray)
                                }
                        .offset(y: -size * 0.05)
                    @unknown default:
                        EmptyView()
                    }
                }
            }
        }
    }
}

#Preview {
    CustomAnnotaitonView(pin: mockPins[0], size: 96, pinColor: .red)
}
