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
    var body: some View {
        GeometryReader {
            let size = $0.size
        }
        .ignoresSafeArea()
        .navigationTransition(.zoom(sourceID: sampleImage.id, in: animation))
    }
}

#Preview {
    StampCardView()
}
