//
//  ARScaleSlider.swift.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/04.
//

import SwiftUI

import SwiftUI

struct ARScaleSlider: View {
    @Binding var arScale: Float

    var body: some View {
        VStack(spacing: 8) {
            Text("\(Int(arScale * 100))%")
                .font(.caption)
                .foregroundColor(.white)
                .padding(4)
                .background(Color.black.opacity(0.5))
                .cornerRadius(6)

            Slider(value: $arScale, in: 0.5...2.0)
                .rotationEffect(.degrees(-90))
                .frame(width: 260)
                .offset(x: -10)
        }
        .frame(width: 40, height: 300)
    }
}

