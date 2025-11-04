//
//  StampCardDetailView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/29.
//

import SwiftUI

struct StampCardDetailView: View {
    var sampleImage: SampleImage
    var animation: Namespace.ID
    @Environment(SharedModel.self) private var sharedModel
    
    /// View Properities
    @State private var hidesThumbnail: Bool = false
    @State private var scrollID: UUID?
    
    var body: some View {
        GeometryReader {
            let size = $0.size
            
            Color.black
            
            ScrollView (.vertical) {
                LazyVStack(spacing: 0) {
                    ForEach(sharedModel.sampleimages) { sampleImage in
                        if let  sampleImage = sampleImage.image {
                            Image(uiImage: sampleImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: size.width, height: size.height)
                                .clipShape(.rect(cornerRadius: 15))
                        }
                    }
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $scrollID)
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .zIndex(hidesThumbnail ? 1 : 0)
            if let  thumbnail = sampleImage.image {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.width, height: size.height)
                    .clipShape(.rect(cornerRadius: 15))
                    .task {
                        scrollID = sampleImage.id
                        try? await Task.sleep(for: .seconds(0.15))
                        hidesThumbnail = true
                    }
            }
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: sampleImage.id, in: animation))
    }
}

#Preview {
    StampCardView()
}
