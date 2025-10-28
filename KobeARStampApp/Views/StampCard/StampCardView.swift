//
//  SwiftUIView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

struct StampCardView: View {
    var sharedModel = SharedModel()
    var body: some View {
        @Bindable var bindings = sharedModel
        NavigationStack {
            VStack(spacing: 0) {
                /// Header View
                HeaderView()
                ScrollView(.vertical) {
                    LazyVGrid(columns: Array(repeating: GridItem(spacing: 10), count: 2),
                              spacing: 10) {
                        ForEach($bindings.sampleimages) { $sampleimage in
                            /// ImageCardView
                            ImageCardView(sampleimage: $sampleimage)
                                .environment(sharedModel)
                        }
                    }
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
    @Environment(SharedModel.self) private var sharedModel
    @Binding var sampleimage: SampleImage
    var body: some View {
        Text("Hello, world!")
    }
}

#Preview {
    StampCardView()
}

