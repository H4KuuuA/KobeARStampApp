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
    @State private var selectedEvent: String = "みんなで!アート探検 in HAT神戸"
    
    // 追加: プロフィール画像を取得
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var profileImage: UIImage?
    
    let eventList = [
        "みんなで!アート探検 in HAT神戸",
        "神戸マラソン2025",
        "ルミナリエスタンプラリー",
        "港町めぐりツアー"
    ]
    
    var body: some View {
        GeometryReader {
            let screenSize: CGSize = $0.size
            
            NavigationStack {
                ScrollView(.vertical) {
                    VStack(spacing: 32) {
                        /// Event Selector (右上)
                        HStack {
                            Spacer()
                            EventSelectorMenu()
                        }
                        
                        /// Progress Bar (真ん中)
                        ZStack {
                            StampProgressBar(
                                stampManager: stampManager,
                                size: 150,
                                showPercentage: false
                            )
                            
                            // 中央に円形の画像を表示
                            if let profileImage = profileImage {
                                // プロフィール画像がある場合
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            } else {
                                // デフォルト画像
                                Image("hatkobe_1")
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                    )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 32)
                        .padding(.bottom, 8)
                        
                        VStack {
                            Text("取得スタンプ数 ")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            HStack {
                                Text("\(stampManager.acquiredStampCount)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(Color("DarkBlue"))
                                    .contentTransition(.numericText())
                                
                                Text("/\(stampManager.totalSpotCount)")
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(red: 0.1, green: 0.1, blue: 0.1))
                            }
                            .animation(.spring(), value: stampManager.acquiredStampCount)
                        }
                        
                        /// Stamp Cards Grid
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2),
                                  spacing: 10) {
                            ForEach(stampManager.allSpots) { spot in
                                /// ImageCardView
                                NavigationLink(value: spot) {
                                    ImageCardView(screenSize: screenSize, spot: spot, stampManager: stampManager)
                                        .frame(height: screenSize.height * 0.4)
                                        .contentShape(Rectangle())
                                        .buttonStyle(CustomButtonStyle())
                                }
                            }
                        }
                                  .padding(.bottom, 56)
                    }
                    .padding(15)
                    .background(
                        // 斜めに二色で切り替え
                        ZStack {
                            // 背景全体(下の色)
                            Color.white
                            
                            // 斜めの三角形(上の色)
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
                    )
                }
                .navigationDestination(for: Spot.self) { spot in
                    StampCardDetailView(spot: spot, animation: animation, stampManager: stampManager)
                        .toolbarVisibility(.hidden, for: .navigationBar)
                }
            }
            .onAppear {
                // プロフィール画像を読み込む
                if let data = profileImageData, let image = UIImage(data: data) {
                    profileImage = image
                }
                
#if DEBUG
                // デバッグ: 最初のスポットを取得済みにする
                stampManager.debugAcquireFirstStamp()
                
                // または複数のスポットを取得
                // stampManager.debugAcquireMultipleStamps(spotIDs: [
                //     "nada-north-plaza",
                //     "minume-shrine",
                //     "nagisa-park"
                // ])
                
                // またはランダムに3個取得
                // stampManager.debugAcquireRandomStamps(count: 3)
#endif
            }
            .onChange(of: profileImageData) { _, newValue in
                // AppStorageの変更を監視
                if let data = newValue, let image = UIImage(data: data) {
                    profileImage = image
                } else {
                    profileImage = nil
                }
            }
        }
    }
    
    // 最大幅を計算する関数
    private func calculateMaxWidth() -> CGFloat {
        let font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        var maxWidth: CGFloat = 0
        
        for event in eventList {
            let attributes = [NSAttributedString.Key.font: font]
            let size = (event as NSString).size(withAttributes: attributes)
            maxWidth = max(maxWidth, size.width)
        }
        
        return maxWidth + 16  // 余白を追加
    }
    
    @ViewBuilder
    func EventSelectorMenu() -> some View {
        Menu {
            ForEach(eventList, id: \.self) { event in
                Button(action: {
                    selectedEvent = event
                }) {
                    HStack {
                        Text(event)
                        if selectedEvent == event {
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
                    
                    Text(selectedEvent)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(width: calculateMaxWidth(), alignment: .center)
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
        GeometryReader {
            let size = $0.size
            
            ZStack {
                // 背景画像
                if let stampImage = stampManager.getImage(for: spot) {
                    // 取得済み: 撮影した画像
                    Image(uiImage: stampImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(15)
                } else if let assetImage = UIImage(named: spot.placeholderImageName) {
                    // 未取得: プレースホルダー画像（グレーアウト）
                    Image(uiImage: assetImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size.width, height: size.height)
                        .clipped()
                        .cornerRadius(15)
                        .grayscale(1)
                        .opacity(0.4)
                        .overlay(
                            Color.black.opacity(0.6)
                                .cornerRadius(15)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(.fill)
                }
                
                // 取得済みのスタンプクリア画像（右上）
                if stampManager.isStampAcquired(spotID: spot.id) {
                    VStack {
                        HStack {
                            Spacer()
                            
                            // StampClear.pngを表示
                            if let stampClearImage = UIImage(named: "StampClear") {
                                Image(uiImage: stampClearImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 100, height: 100)
                                    .padding(6)
                            } else {
                                // StampClear.pngが見つからない場合はチェックマーク
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
                        // グラデーション背景（上から下に向かって濃くなる）
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
                        
                        // エリア名テキスト
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
}

/// Custom Button Style
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    StampCardView(stampManager: StampManager())
}
