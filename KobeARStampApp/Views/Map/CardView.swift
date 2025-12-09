//
//  SpotCardView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/15.
//

import SwiftUI

struct SpotCardView: View {
    let spot: Spot
    @ObservedObject var stampManager: StampManager
    let onDismiss: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 0) {
                    // 画像表示
                    imageView
                    
                    // スポット情報
                    VStack(alignment: .leading, spacing: 4) {
                        Text(spot.name)
                            .font(.title2)
                            .bold()
                        
                        if let subtitle = spot.subtitle {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 24) {
                            if let category = spot.category {
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            
                            StampStatusBadge(isAcquired: stampManager.isStampAcquired(spotID: spot.id))
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
            
            // ×ボタン
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
    
    // MARK: - Image View
    @ViewBuilder
    private var imageView: some View {
        if let imageURL = spot.imageURL {
            // 外部URLから画像を取得（ローカル画像をフォールバックとして表示）
            AsyncImage(url: imageURL) { phase in
                switch phase {
                case .empty:
                    // 読み込み中: ローカル画像を表示
                    placeholderImage
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 120)
                        .clipped()
                        .cornerRadius(12)
                case .failure:
                    // 取得失敗: ローカル画像を表示
                    placeholderImage
                @unknown default:
                    placeholderImage
                }
            }
        } else {
            // URLがない場合: ローカル画像を使用
            placeholderImage
        }
    }
    
    @ViewBuilder
    private var placeholderImage: some View {
        if let localImage = UIImage(named: spot.placeholderImageName) {
            Image(uiImage: localImage)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 120)
                .clipped()
                .cornerRadius(12)
        } else {
            Image(systemName: "photo")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 120)
                .foregroundColor(.gray)
        }
    }
}

#Preview {
    SpotCardView(
        spot: StampManager.defaultSpots[0],
        stampManager: StampManager(),
        onDismiss: {}
    )
    .background(Color.gray.opacity(0.2))
}
