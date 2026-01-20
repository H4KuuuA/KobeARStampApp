//
//  StampCardView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

struct StampCardView: View {
    @ObservedObject var stampManager: StampManager
    @Namespace private var animation
    @State private var selectedEvent: Event?
    @State private var availableEvents: [Event] = []
    @State private var selectedSpot: Spot?
    @State private var isUserSelectedEvent = false
    
    // 追加: プロフィール画像を取得
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var profileImage: UIImage?
    
    // イニシャライザを追加(引数なしで呼び出せるように)
    init() {
        self.stampManager = StampManager.shared
    }

    init(stampManager: StampManager) {
        self.stampManager = stampManager
    }
    
    // 表示するスポットを動的に決定
    private var displayedSpots: [Spot] {
        if selectedEvent != nil {
            return stampManager.currentEventSpots
        } else {
            return stampManager.allSpots
        }
    }
    
    // 🔧 修正: 取得済みスタンプ数を計算
    private var displayedAcquiredCount: Int {
        if selectedEvent != nil {
            return stampManager.currentEventAcquiredCount
        } else {
            return stampManager.acquiredStampCount
        }
    }
    
    // 🔧 修正: 総スポット数を計算
    private var displayedTotalCount: Int {
        if selectedEvent != nil {
            return stampManager.currentEventSpotCount
        } else {
            return stampManager.totalSpotCount
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            contentView(screenSize: geometry.size)
        }
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private func contentView(screenSize: CGSize) -> some View {
        NavigationStack {
            ScrollView(.vertical) {
                mainContent(screenSize: screenSize)
            }
            .navigationDestination(item: $selectedSpot) { spot in
                StampCardDetailView(
                    spot: spot,
                    animation: animation,
                    stampManager: stampManager,
                    spots: displayedSpots
                )
                .toolbarVisibility(.hidden, for: .navigationBar)
            }
        }
        .task {
            await loadInitialData()
        }
        .onAppear {
            if !isUserSelectedEvent {
                Task {
                    await stampManager.fetchCurrentEvent()
                    resetToCurrentEvent()
                }
            }
        }
        .onChange(of: profileImageData) { oldValue, newValue in
            if let data = newValue, let image = UIImage(data: data) {
                profileImage = image
            } else {
                profileImage = nil
            }
        }
        .onChange(of: selectedEvent) { oldValue, newEvent in
            if selectedSpot != nil {
                selectedSpot = nil
            }
            
            Task {
                if let event = newEvent {
                    await stampManager.fetchSpots(for: event)
                }
            }
        }
        .onChange(of: stampManager.currentEvent) { oldValue, newValue in
            if !isUserSelectedEvent {
                resetToCurrentEvent()
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private func mainContent(screenSize: CGSize) -> some View {
        VStack(spacing: 32) {
            // Event Selector
            HStack {
                Spacer()
                EventSelectorMenu()
            }
            
            // Progress Bar with Profile Image
            profileSection
            
            // Stamp Count
            stampCountSection
            
            // Stamp Cards Grid
            stampGridSection(screenSize: screenSize)
        }
        .padding(15)
        .background(diagonalBackground(screenSize: screenSize))
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        ZStack {
            StampProgressBar(
                stampManager: stampManager,
                size: 150,
                showPercentage: false,
                useEventProgress: selectedEvent != nil
            )
            
            profileImageView
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 32)
        .padding(.bottom, 8)
    }
    
    @ViewBuilder
    private var profileImageView: some View {
        if let profileImage = profileImage {
            Image(uiImage: profileImage)
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        } else {
            Image("hatkobe_1")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white, lineWidth: 2))
        }
    }
    
    // MARK: - Stamp Count Section
    
    private var stampCountSection: some View {
        VStack {
            Text("取得スタンプ数 ")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            
            HStack {
                Text("\(displayedAcquiredCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color("DarkBlue"))
                    .contentTransition(.numericText())
                
                Text("/\(displayedTotalCount)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
            }
            .animation(.spring(), value: displayedAcquiredCount)
        }
    }
    
    // MARK: - Stamp Grid Section
    
    @ViewBuilder
    private func stampGridSection(screenSize: CGSize) -> some View {
        ZStack {
            if stampManager.isLoadingEventSpots {
                loadingView
            } else if displayedSpots.isEmpty {
                emptyStateView
            } else {
                spotGridView(screenSize: screenSize)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: stampManager.isLoadingEventSpots)
        .animation(.easeInOut(duration: 0.3), value: displayedSpots.count)
        .padding(.bottom, 56)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("スポットを読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "map.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("スポットがありません")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    @ViewBuilder
    private func spotGridView(screenSize: CGSize) -> some View {
        let columns = Array(repeating: GridItem(spacing: 10), count: 2)
        
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(displayedSpots) { spot in
                Button {
                    selectedSpot = spot
                } label: {
                    ImageCardView(screenSize: screenSize, spot: spot, stampManager: stampManager)
                        .frame(height: screenSize.height * 0.4)
                }
                .buttonStyle(CustomButtonStyle())
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private func diagonalBackground(screenSize: CGSize) -> some View {
        ZStack {
            Color.white
            
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: screenSize.height * 0.30))
                    path.addLine(to: CGPoint(x: 0, y: screenSize.height * 0.20))
                    path.closeSubpath()
                }
                .fill(Color(.gray).opacity(0.1))
            }
        }
    }
    
    // MARK: - Event Handlers
    
    private func loadInitialData() async {
        if let data = profileImageData, let image = UIImage(data: data) {
            profileImage = image
        }
        
        await fetchAvailableEvents()
        resetToCurrentEvent()
    }
    
    private func resetToCurrentEvent() {
        let currentEvent = stampManager.currentEvent
        
        if selectedEvent?.id != currentEvent?.id {
            selectedEvent = currentEvent
            
            if let event = currentEvent {
                Task {
                    await stampManager.fetchSpots(for: event)
                }
            }
        }
    }
    
    // MARK: - Fetch Available Events
    
    private func fetchAvailableEvents() async {
        do {
            let response = try await SupabaseManager.shared.client
                .from("events")
                .select()
                .eq("status", value: true)
                .eq("is_public", value: true)
                .order("start_time", ascending: false)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let events = try decoder.decode([Event].self, from: response.data)
            
            await MainActor.run {
                self.availableEvents = events
                print("✅ Available events fetched: \(events.count)")
            }
        } catch {
            print("❌ Error fetching available events: \(error)")
        }
    }
    
    @ViewBuilder
    func EventSelectorMenu() -> some View {
        Menu {
            ForEach(availableEvents) { event in
                Button(action: {
                    isUserSelectedEvent = true
                    selectedEvent = event
                }) {
                    HStack {
                        Text(event.name)
                        if selectedEvent?.id == event.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 8) {
                VStack(alignment: .center, spacing: 4) {
                    Text("イベント")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(selectedEvent?.name ?? "イベントを選択")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(minWidth: 80, maxWidth: 180)
                }
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color("DarkBlue"))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        }
    }
}

struct ImageCardView: View {
    var screenSize: CGSize
    let spot: Spot
    @ObservedObject var stampManager: StampManager
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            ZStack {
                // 背景画像
                if let stampImage = stampManager.getImage(for: spot) {
                    Image(uiImage: stampImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(15)
                } else {
                    spotImageView(size: size)
                        .grayscale(1)
                        .opacity(0.4)
                        .overlay(
                            Color.black.opacity(0.6)
                                .cornerRadius(15)
                        )
                }
                
                // 取得済みのスタンプクリア画像(右上)
                if stampManager.isStampAcquired(spotID: spot.id) {
                    VStack {
                        HStack {
                            Spacer()
                            
                            if let stampClearImage = UIImage(named: "StampClear") {
                                Image(uiImage: stampClearImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .padding(6)
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 28, height: 28)
                                    
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.green)
                                }
                                .padding(8)
                            }
                        }
                        Spacer()
                    }
                }
                
                // スタンプ名を下部にグラデーションで表示
                VStack {
                    Spacer()
                    
                    ZStack(alignment: .bottom) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.black.opacity(0.8)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 80)
                        .cornerRadius(15)
                        
                        Text(spot.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func spotImageView(size: CGSize) -> some View {
        if let imageUrlString = spot.imageUrl, let imageUrl = URL(string: imageUrlString) {
            AsyncImage(url: imageUrl) { phase in
                switch phase {
                case .empty:
                    ZStack {
                        Color.gray.opacity(0.3)
                        ProgressView()
                    }
                    .frame(width: size.width, height: size.height)
                    .cornerRadius(15)
                    
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(15)
                    
                case .failure:
                    placeholderImageView(size: size)
                    
                @unknown default:
                    placeholderImageView(size: size)
                }
            }
        } else {
            placeholderImageView(size: size)
        }
    }
    
    @ViewBuilder
    private func placeholderImageView(size: CGSize) -> some View {
        if let assetImage = UIImage(named: spot.placeholderImageName) {
            Image(uiImage: assetImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(15)
        } else {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.3))
                .frame(width: size.width, height: size.height)
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
}

struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    StampCardView()
}
