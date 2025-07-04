//
//  ARScaleSlider.swift.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/04.
//

import SwiftUI

struct ARScaleSlider: View {
    @Binding var arScale: Float

    var body: some View {
        VStack(spacing: 8) {
            // パーセンテージ表示
            Text("\(Int(arScale * 100))%")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(6)

            // 縦スライダー本体
            Slider(value: $arScale, in: 0.5...2.0)
                .rotationEffect(.degrees(-90))
                .frame(width: 90, height: 450)
                .accentColor(.cyan)
        }
        .frame(height: 500)
    }
}
