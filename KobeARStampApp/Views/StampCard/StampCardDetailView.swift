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
    @State private var expandedSpotID: String? = nil  // 展開中のスポットID
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                Color.black
                
                mainScrollView(size: size)
                
                if !hidesThumbnail {
                    thumbnailView(size: size)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: spot.id, in: animation))
    }
    
    // メインのスクロールビュー
    @ViewBuilder
    private func mainScrollView(size: CGSize) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(stampManager.allSpots) { spot in
                    spotCardView(spot: spot, size: size)
                        .id(spot.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $scrollID)
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .zIndex(hidesThumbnail ? 1 : 0)
    }
    
    // 各スポットのカードビュー
    @ViewBuilder
    private func spotCardView(spot: Spot, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            spotImageView(spot: spot, size: size)
            spotInfoOverlay(spot: spot, size: size)
        }
    }
    
    // スポット画像
    @ViewBuilder
    private func spotImageView(spot: Spot, size: CGSize) -> some View {
        if let stampImage = stampManager.getImage(for: spot) {
            Image(uiImage: stampImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
        } else if let placeholderImage = UIImage(named: spot.placeholderImageName) {
            Image(uiImage: placeholderImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
        } else {
            Color.gray
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
        }
    }
    
    // スポット情報のオーバーレイ
    @ViewBuilder
    private func spotInfoOverlay(spot: Spot, size: CGSize) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if expandedSpotID == spot.id {
                    expandedSpotID = nil
                } else {
                    expandedSpotID = spot.id
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                headerView(spot: spot)
                
                if let subtitle = spot.subtitle {
                    subtitleView(subtitle: subtitle)
                }
                
                if let stamp = stampManager.acquiredStamps[spot.id] {
                    dateView(date: stamp.acquiredDate)
                }
                
                if let description = spot.description {
                    HStack(spacing: 4) {
                        Text("詳細説明")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        Image(systemName: expandedSpotID == spot.id ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 4)
                    
                    if expandedSpotID == spot.id {
                        descriptionView(description: description, maxHeight: size.height * 0.18)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                VStack {
                    gradientBackground(isExpanded: expandedSpotID == spot.id)
                    Spacer()
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // ヘッダー（タイトルとバッジ）
    @ViewBuilder
    private func headerView(spot: Spot) -> some View {
        HStack {
            Text(spot.name)
                .font(.title2.bold())
                .foregroundColor(.white)
            
            Spacer()
            
            StampStatusBadge(isAcquired: stampManager.isStampAcquired(spotID: spot.id))
        }
    }
    
    // サブタイトル
    @ViewBuilder
    private func subtitleView(subtitle: String) -> some View {
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
    }
    
    // 取得日時
    @ViewBuilder
    private func dateView(date: Date) -> some View {
        Text("取得日時: \(date.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
    }
    
    // 説明文（スクロール可能）
    @ViewBuilder
    private func descriptionView(description: String, maxHeight: CGFloat) -> some View {
        ScrollView {
            Text(description)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .padding(.top, 8)
        }
        .frame(maxHeight: maxHeight)
    }
    
    // グラデーション背景
    @ViewBuilder
    private func gradientBackground(isExpanded: Bool) -> some View {
        let topColor = Color.black.opacity(0.85)
        let midColor = Color.black.opacity(0.6)
        let bottomColor = Color.clear
        
        LinearGradient(
            colors: [topColor, midColor, bottomColor],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: isExpanded ? 280 : 200)
    }
    
    // サムネイル（初期表示用）
    @ViewBuilder
    private func thumbnailView(size: CGSize) -> some View {
        if let stampImage = stampManager.getImage(for: spot) {
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
}


