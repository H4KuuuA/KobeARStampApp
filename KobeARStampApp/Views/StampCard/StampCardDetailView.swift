//
//  StampCardDetailView.swift
//  KobeARStampApp
//
//  Supabase対応版
//

import SwiftUI

struct StampCardDetailView: View {
    let spot: Spot
    var animation: Namespace.ID
    @ObservedObject var stampManager = StampManager.shared
    
    // 表示するスポットのリスト(親Viewから渡される)
    let spots: [Spot]
    
    var isScrollEnabled: Bool = true
    
    /// View Properties
    @State private var hidesThumbnail: Bool = false
    @State private var scrollID: UUID?
    @State private var expandedSpotID: UUID? = nil
    
    // Supabaseから取得した訪問日時
    @State private var visitedDates: [UUID: Date] = [:]
    
    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            
            ZStack {
                Color.black
                
                if isScrollEnabled {
                    mainScrollView(size: size)
                } else {
                    spotCardView(spot: spot, size: size)
                }
                
                if !hidesThumbnail {
                    thumbnailView(size: size)
                }
            }
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: spot.id.uuidString, in: animation))
        .onAppear {
            // スクロール位置を即座に設定
            if isScrollEnabled && scrollID == nil {
                scrollID = spot.id
            }
        }
        .task {
            // 訪問日時を取得
            await loadVisitedDates()
        }
    }
    
    // MARK: - Data Loading
    
    /// Supabaseから訪問日時を取得
    private func loadVisitedDates() async {
        guard AuthManager.shared.isAuthenticated else { return }
        
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            // 表示中のスポットIDリストを取得
            let spotIds = spots.map { $0.id.uuidString }
            
            let response = try await SupabaseManager.shared.client
                .from("spot_visit")
                .select("spot_id, visited_at")
                .eq("user_id", value: userId.uuidString)
                .in("spot_id", values: spotIds)
                .order("visited_at", ascending: false)
                .execute()
            
            struct VisitRecord: Codable {
                let spot_id: String
                let visited_at: String
            }
            
            let decoder = JSONDecoder()
            let records = try decoder.decode([VisitRecord].self, from: response.data)
            
            // 各スポットの最新訪問日時を保存
            var dates: [UUID: Date] = [:]
            let isoFormatter = ISO8601DateFormatter()
            
            for record in records {
                if let spotId = UUID(uuidString: record.spot_id),
                   let date = isoFormatter.date(from: record.visited_at) {
                    // 既に登録されていない、または新しい日時の場合のみ更新
                    if dates[spotId] == nil || date > dates[spotId]! {
                        dates[spotId] = date
                    }
                }
            }
            
            visitedDates = dates
            
        } catch {
            print("❌ 訪問日時の取得エラー: \(error)")
        }
    }
    
    // MARK: - Main Scroll View
    
    @ViewBuilder
    private func mainScrollView(size: CGSize) -> some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(spots) { spot in
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
    
    // MARK: - Spot Card View
    @ViewBuilder
    private func spotCardView(spot: Spot, size: CGSize) -> some View {
        ZStack(alignment: .top) {
            spotImageView(spot: spot, size: size)
            spotInfoOverlay(spot: spot, size: size)
        }
    }
    
    // MARK: - Image View
    @ViewBuilder
    private func spotImageView(spot: Spot, size: CGSize) -> some View {
        // スタンプ取得済みならその画像、なければプレイスホルダー
        if let stampImage = stampManager.getImage(for: spot) {
            Image(uiImage: stampImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
        } else {
            // 未取得: imageUrl または placeholderImageName を表示
            spotAsyncImageView(spot: spot, size: size)
        }
    }
    
    @ViewBuilder
    private func spotAsyncImageView(spot: Spot, size: CGSize) -> some View {
        if let imageUrlString = spot.imageUrl, let imageUrl = URL(string: imageUrlString) {
            // imageUrl がある場合: AsyncImageで読み込み
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
                    
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipShape(.rect(cornerRadius: 15))
                    
                case .failure:
                    placeholderOrFallback(spot: spot, size: size)
                    
                @unknown default:
                    placeholderOrFallback(spot: spot, size: size)
                }
            }
        } else {
            placeholderOrFallback(spot: spot, size: size)
        }
    }
    
    @ViewBuilder
    private func placeholderOrFallback(spot: Spot, size: CGSize) -> some View {
        if let placeholderImage = UIImage(named: spot.placeholderImageName) {
            Image(uiImage: placeholderImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
        } else {
            Color.gray.opacity(0.3)
                .frame(width: size.width, height: size.height)
                .clipShape(.rect(cornerRadius: 15))
                .overlay(
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("画像なし")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                )
        }
    }
    
    // MARK: - Info Overlay
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
                
                // subtitle が Optional(String?) のため、安全にアンラップして空文字でないときだけ表示
                if let subtitle = spot.subtitle, !subtitle.isEmpty {
                    subtitleView(subtitle: subtitle)
                }
                
                // スタンプ取得情報の表示
                if let visitedDate = visitedDates[spot.id] {
                    dateView(date: visitedDate)
                }
                
                // description が空文字でなければ表示
                if !spot.description.isEmpty {
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
                        descriptionView(description: spot.description, maxHeight: size.height * 0.18)
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
    
    // MARK: - Sub Components
    
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
    
    @ViewBuilder
    private func subtitleView(subtitle: String) -> some View {
        Text(subtitle)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.8))
    }
    
    @ViewBuilder
    private func dateView(date: Date) -> some View {
        Text("取得日時: \(date.formatted(date: .abbreviated, time: .shortened))")
            .font(.caption)
            .foregroundColor(.white.opacity(0.6))
    }
    
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
    
    // MARK: - Thumbnail View (Initial Transition)
    @ViewBuilder
    private func thumbnailView(size: CGSize) -> some View {
        Group {
            if let stampImage = stampManager.getImage(for: spot) {
                Image(uiImage: stampImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if let placeholderImage = UIImage(named: spot.placeholderImageName) {
                Image(uiImage: placeholderImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.gray
            }
        }
        .frame(width: size.width, height: size.height)
        .clipShape(.rect(cornerRadius: 15))
        .task {
            try? await Task.sleep(for: .seconds(0.15))
            hidesThumbnail = true
        }
    }
}


// MARK: - Preview
#Preview {
    @Previewable @Namespace var animation

    let previewSpot = Spot(
        id: UUID(),
        name: "神戸ポートタワー",
        subtitle: "美しい夜景スポット",
        description: "赤いランドマークタワーです。",
        address: "兵庫県神戸市中央区波止場町5-5",
        latitude: 34.6826,
        longitude: 135.1867,
        radius: 50,
        category: "観光",
        pinColor: "#FF0000",
        imageUrl: nil,
        arModelId: nil,
        isActive: true,
        createdByUser: nil,
        createdAt: Date(),
        updatedAt: nil,
        deletedAt: nil
    )
    
    StampCardDetailView(
        spot: previewSpot,
        animation: animation,
        spots: [previewSpot]
    )
}
