//
//  SwiftUIView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

struct StampCardView: View {
    var sharedModel = SharedModel()
    @Namespace private var animation
    @State private var progress: CGFloat = 7  // 進捗データ（必要に応じて変更）
    @State private var selectedEvent: String = "みんなで!アート探検 in HAT神戸"
    
    // イベントのリスト
    let eventList = [
        "みんなで!アート探検 in HAT神戸",
        "神戸マラソン2025",
        "ルミナリエスタンプラリー",
        "港町めぐりツアー"
    ]
    
    var body: some View {
        @Bindable var bindings = sharedModel
        GeometryReader {
            let screenSize: CGSize = $0.size
            
            NavigationStack {
                VStack(spacing: 0) {
                    
                    ScrollView(.vertical) {
                        VStack(spacing: 64) {
                            /// Event Selector (右上)
                            HStack {
                                Spacer()
                                EventSelectorMenu()
                            }
                            
                            /// Progress Bar (真ん中)
                            ZStack {
                                StampProgressBar(
                                    progress: progress,
                                    size: 150,
                                    showPercentage: false
                                )
                                
                                // 中央に円形の画像を表示
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
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            /// Stamp Cards Grid
                            LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2),
                                      spacing: 10) {
                                ForEach($bindings.sampleimages) { $sampleimage in
                                    /// ImageCardView
                                    NavigationLink(value: sampleimage) {
                                        ImageCardView(screenSize: screenSize , sampleimage: $sampleimage)
                                            .environment(sharedModel)
                                            .frame(height: screenSize.height * 0.4)
                                            .contentShape(Rectangle())
                                            .matchedTransitionSource(id: sampleimage, in: animation) {
                                                $0
                                                    .background(.clear)
                                            }
                                            .buttonStyle(CustomButtonStyle())
                                    }
                                }
                            }
                        }
                        .padding(15)
                    }
                }
                .navigationDestination(for: SampleImage.self) { sampleImage in
                    StampCardDetailView(sampleImage: sampleImage, animation: animation)
                        .environment(sharedModel)
                        .toolbarVisibility(.hidden, for: .navigationBar)
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
    
    @ViewBuilder
    func HeaderView() -> some View {
        HStack {
            Button {
                
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.title3)
            }
            
            Spacer()
            
            Button {
                
            } label: {
                Image(systemName: "person.fill")
                    .font(.title3)
            }
        }
        .overlay {
            Text("スタンプカード")
                .font(.title3.bold())
        }
        .foregroundStyle(Color.primary)
        .padding(15)
        .background(.ultraThinMaterial)
    }
}

struct ImageCardView: View {
    var screenSize: CGSize
    @Environment(SharedModel.self) private var sharedModel
    @Binding var sampleimage: SampleImage
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            if let uiImage = sampleimage.image {
                // ① URL画像が読み込まれた場合
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(15)
            } else if let assetName = sampleimage.assetName,
                      let assetImage = UIImage(named: assetName) {
                // ② URL画像がない場合はAssets画像
                Image(uiImage: assetImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .cornerRadius(15)
            } else {
                RoundedRectangle(cornerRadius: 15)
                    .fill(.fill)
                    .task(priority: .high){
                        // URLがある場合のみ非同期読み込み
                        if sampleimage.fileURL != nil {
                            await sharedModel.loadImage(for: $sampleimage)
                        }
                    }
            }
        }
    }
}

/// Custom Buitton Style
struct CustomButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

#Preview {
    StampCardView()
}
