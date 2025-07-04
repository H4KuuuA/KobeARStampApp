//
//  FilterSelectionView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/01.
//

// FilterSelectionView.swift
import SwiftUI

struct FilterSelectionView: View {
    let originalImage: UIImage
    @Binding var selectedFilter: String
    @Binding var filteredImage: UIImage

    // 使用可能なフィルター一覧
    let filterList = [
        "Normal",
        "CIPhotoEffectNoir",
        "CIPhotoEffectChrome",
        "CIPhotoEffectInstant",
        "CIPhotoEffectProcess",
        "CIPhotoEffectTransfer",
        "CISepiaTone"
    ]

    var body: some View {
        VStack(spacing: 12) {
            Text("フィルターを選択")
                .font(.headline)
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(filterList, id: \.self) { filterName in
                        VStack(spacing: 4) {
                            Image(uiImage: filteredThumbnail(for: filterName))
                                .resizable()
                                .frame(width: 80, height: 80)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(filterName == selectedFilter ? Color.blue : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedFilter = filterName
                                    filteredImage = applyFilter(to: originalImage, filterName: filterName)
                                }

                            Text(filterLabel(for: filterName))
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.9))
    }

    func filteredThumbnail(for filterName: String) -> UIImage {
        return applyFilter(to: originalImage, filterName: filterName)
    }

    func applyFilter(to image: UIImage, filterName: String) -> UIImage {
        if filterName == "Normal" {
            return image
        }
        return ARSnapshotManager.applyFilter(to: image, filterName: filterName)
    }

    func filterLabel(for filterName: String) -> String {
        switch filterName {
        case "CIPhotoEffectNoir": return "Noir"
        case "CIPhotoEffectChrome": return "Chrome"
        case "CIPhotoEffectInstant": return "Instant"
        case "CIPhotoEffectProcess": return "Process"
        case "CIPhotoEffectTransfer": return "Transfer"
        case "CISepiaTone": return "Sepia"
        default: return "Normal"
        }
    }
}
