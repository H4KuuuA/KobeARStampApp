//
//  FilterSelectionView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/01.
//

// FilterSelectionView.swift
import SwiftUI

struct FilterSelectionView: View {
    var originalImage: UIImage
    @Binding var selectedFilter: String
    @Binding var filteredImage: UIImage

    let filterList = ARSnapshotManager.availableFilters()

    var body: some View {
        VStack {
            Text("フィルターを選択").font(.headline)

            // プレビュー表示
            Image(uiImage: filteredImage)
                .resizable()
                .scaledToFit()
                .frame(height: 300)
                .cornerRadius(10)
                .padding()

            // 横スクロールフィルター一覧
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(filterList, id: \.self) { filterName in
                        VStack {
                            Image(uiImage: ARSnapshotManager.applyFilter(to: originalImage, filterName: filterName))
                                .resizable()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(filterName == selectedFilter ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedFilter = filterName
                                    filteredImage = ARSnapshotManager.applyFilter(to: originalImage, filterName: filterName)
                                }

                            Text(filterLabel(for: filterName))
                                .font(.caption2)
                        }
                        .padding(.horizontal, 4)
                    }

                }
                .padding(.horizontal)
            }
        }
    }

    /// フィルター表示名の整形
    func filterLabel(for filterName: String) -> String {
        filterName
            .replacingOccurrences(of: "CIPhotoEffect", with: "")
            .replacingOccurrences(of: "CI", with: "")
    }
}
