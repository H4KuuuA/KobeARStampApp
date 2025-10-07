//
//  PreviewAndFilter.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import SwiftUI

struct PreviewAndFilterView: View {
    let originalImage: UIImage
    @Binding var isPresented: Bool
    
    @State private var filteredImage: UIImage
    @State private var selectedFilter: String = "Normal"

    init(originalImage: UIImage, isPresented: Binding<Bool>) {
        self.originalImage = originalImage
        self._isPresented = isPresented
        // Stateの初期値として、フィルターのかかっていない元の画像を設定
        _filteredImage = State(initialValue: originalImage)
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // ヘッダー (閉じる、保存ボタン)
                HStack {
                    Button("閉じる") { isPresented = false }
                    Spacer()
                    Button("保存") {
                        UIImageWriteToSavedPhotosAlbum(filteredImage, nil, nil, nil)
                        isPresented = false
                    }
                }
                .padding()
                .foregroundColor(.white)
                .font(.headline)

                // プレビュー画像
                Image(uiImage: filteredImage)
                    .resizable()
                    .scaledToFit()
                
                Spacer()
                
                // フィルター選択ビュー
                FilterSelectionView(
                    originalImage: originalImage,
                    selectedFilter: $selectedFilter,
                    filteredImage: $filteredImage
                )
            }
        }
    }
}
