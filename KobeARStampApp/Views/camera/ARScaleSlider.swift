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
        ZStack {
            // 1. ベースとなるスライダー
            Slider(value: $arScale, in: 0.5...2.0)
                .rotationEffect(.degrees(-90)) // 縦向きにする
                .tint(.cyan)
                // この`width`が、回転後のスライダーの「長さ」になります
                .frame(width: 220)

            // 2. 上に重ねるパーセンテージ表示
            Text("\(Int(arScale * 100))%")
                .font(.caption.bold())
                .foregroundColor(.white)
                .padding(6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)
                .offset(y: -130)
        }
        
        .frame(width: 50, height: 280)
    }
}


