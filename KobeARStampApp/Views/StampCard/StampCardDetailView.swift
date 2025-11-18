//
//  StampCardDetailView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/29.
//

import SwiftUI

struct StampCardDetailView: View {
    let spot: Spot
    var animation: Namespace.ID
    @ObservedObject var stampManager: StampManager
    
    /// View Properties
    @State private var hidesThumbnail: Bool = false
    @State private var scrollID: String?
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            Color.black
            
            ScrollView(.vertical) {
                LazyVStack(spacing: 0) {
                    // 全てのスポットを表示（未取得も含む）
                    ForEach(stampManager.allSpots) { spot in
                        ZStack(alignment: .top) {
                            // 画像表示
                            if let stampImage = stampManager.getImage(for: spot) {
                                // 取得済み: 撮影した写真
                                Image(uiImage: stampImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size.width, height: size.height)
                                    .clipShape(.rect(cornerRadius: 15))
                            } else if let placeholderImage = UIImage(named: spot.placeholderImageName) {
                                // 未取得: プレースホルダー画像
                                Image(uiImage: placeholderImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: size.width, height: size.height)
                                    .clipShape(.rect(cornerRadius: 15))
                            } else {
                                // フォールバック
                                Color.gray
                                    .frame(width: size.width, height: size.height)
                                    .clipShape(.rect(cornerRadius: 15))
                            }
                            
                            // スポット情報オーバーレイ（上部に配置）
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(spot.name)
                                        .font(.title2.bold())
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    // 取得済みバッジ
                                    if stampManager.isStampAcquired(spotID: spot.id) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                            Text("取得済み")
                                                .font(.caption.bold())
                                                .foregroundColor(.blue)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                    } else {
                                        HStack(spacing: 4) {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.gray)
                                            Text("未取得")
                                                .font(.caption.bold())
                                                .foregroundColor(.gray)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                if let subtitle = spot.subtitle {
                                    Text(subtitle)
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                                
                                if let stamp = stampManager.acquiredStamps[spot.id] {
                                    Text("取得日時: \(stamp.acquiredDate.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                LinearGradient(
                                    colors: [.black.opacity(0.8), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .id(spot.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .zIndex(hidesThumbnail ? 1 : 0)
            
            // サムネイル（初期表示用）
            if let stampImage = stampManager.getImage(for: spot) {
                // 取得済み: 撮影した写真
                Image(uiImage: stampImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
                    .task {
                        scrollID = spot.id
                        try? await Task.sleep(for: .seconds(0.15))
                        hidesThumbnail = true
                    }
            } else if let placeholderImage = UIImage(named: spot.placeholderImageName) {
                // 未取得: プレースホルダー画像
                Image(uiImage: placeholderImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
                    .task {
                        scrollID = spot.id
                        try? await Task.sleep(for: .seconds(0.15))
                        hidesThumbnail = true
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: spot.id, in: animation))
    }
}

#Preview {
    @Previewable @Namespace var animation
    let stampManager = StampManager()
    let previewSpot = stampManager.allSpots.first ?? Spot(
        id: "preview",
        name: "Preview Spot",
        placeholderImageName: "hatkobe_1",
        modelName: "box.usdz"
    )
    
    return StampCardDetailView(
        spot: previewSpot,
        animation: animation,
        stampManager: stampManager
    )
}
