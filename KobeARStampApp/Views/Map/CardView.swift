//
//  CustomPinDetailView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/15.
//

import SwiftUI

struct CardView: View {
    let pin: CustomPin
    let onDismiss: () -> Void // ← 親からdismiss動作を注入

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 0) {
                    if let imageURL = pin.imageURL {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(width: 150, height: 120)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 150, height: 80)
                                    .clipped()
                                    .cornerRadius(12)
                            case .failure:
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 150, height: 120)
                                    .foregroundColor(.gray)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(pin.title)
                            .font(.title2)
                            .bold()

                        Text(pin.subtitle ?? "")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack(spacing: 24) {
                            if let category = pin.category {
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }

                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(Color.black.opacity(0.85))

                                Text("約350m") // 仮の距離
                                    .font(.caption)
                                    .foregroundStyle(Color.black.opacity(0.85))
                            }
                        }
                        .padding(.top, 6)
                    }
                    .padding(.leading)
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.regularMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
            )

            // ✕ボタン（カードの外にオフセットして表示）
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .offset(x: -15, y: -40)
            .zIndex(1)
        }
    }
}

#Preview {
    CardView(pin: mockPins[0], onDismiss: {})
        .background(Color.gray.opacity(0.2))
}
