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
    var body: some View {
        @Bindable var bindings = sharedModel
        GeometryReader {
            let screenSize: CGSize = $0.size
            
            NavigationStack {
                VStack(spacing: 0) {
                    /// Header View
                    HeaderView()
                    ScrollView(.vertical) {
                        LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2),
                                  spacing: 10) {
                            ForEach($bindings.sampleimages) { $sampleimage in
                                /// ImageCardView
                                NavigationLink(value: sampleimage) {
                                    ImageCardView(screenSize: screenSize , sampleimage: $sampleimage)
                                        .environment(sharedModel)
                                        .frame(height: screenSize.height * 0.4)
                                        .matchedTransitionSource(id: sampleimage, in: animation) {
                                            $0
                                                .background(.clear)
                                                .clipShape(.rect(cornerRadius: 15))
                                        }
                                }
                                .buttonStyle(CustomButtonStyle())
                            }
                        }
                                  .padding(15)
                    }
                }
                .navigationDestination(for: SampleImage.self) { sampleImage in
                    
                }
            }
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

