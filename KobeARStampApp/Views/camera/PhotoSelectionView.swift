//
//  PhotoSelectionView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import SwiftUI

struct PhotoSelectionView: View {
    // 表示する写真のアセット
    @Binding var assets: [PhotoAsset]
    // このビュー（シート）を閉じるためのBinding
    @Binding var isPresented: Bool
    // ユーザーが写真を選択した後の処理（フィルター画面へ遷移など）
    var onPhotoSelected: (UIImage) -> Void
    
    // ユーザーがグリッドで選択中の写真
    @State private var selectedAssetID: UUID?
    
    // グリッドのレイアウト設定
    private let columns: [GridItem] = Array(repeating: .init(.flexible()), count: 3)

    var body: some View {
        ZStack {
            Color.black.opacity(0.95).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // ヘッダー
                HStack {
                    Text("写真を選択")
                        .font(.headline)
                    Spacer()
                    Button("閉じる") {
                        isPresented = false
                    }
                }
                .padding()
                .foregroundColor(.white)
                
                // 写真一覧のグリッド表示
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 2) {
                        ForEach(assets) { asset in
                            Image(uiImage: asset.image)
                                .resizable()
                                .scaledToFill()
                                .aspectRatio(1, contentMode: .fill)
                                .clipped()
                                .overlay(
                                    // 選択されている場合に枠線を表示
                                    RoundedRectangle(cornerRadius: 0)
                                        .stroke(selectedAssetID == asset.id ? Color.yellow : Color.clear, lineWidth: 4)
                                )
                                .onTapGesture {
                                    selectedAssetID = asset.id
                                }
                        }
                    }
                }
                
                // フッターの操作ボタン
                HStack(spacing: 20) {
                    // 撮り直しボタン
                    Button(action: {
                        assets = [] // 写真をすべてクリア
                        isPresented = false // シートを閉じてカメラに戻る
                    }) {
                        Text("撮り直す")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .cornerRadius(10)
                    }
                    
                    // この写真にするボタン
                    Button(action: {
                        if let selectedID = selectedAssetID,
                           let selectedAsset = assets.first(where: { $0.id == selectedID }) {
                            // 選択した写真で次の処理へ
                            onPhotoSelected(selectedAsset.image)
                        }
                    }) {
                        Text("この写真にする")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedAssetID == nil ? Color.gray : Color.blue) // 未選択時はグレーアウト
                            .cornerRadius(10)
                    }
                    .disabled(selectedAssetID == nil) // 写真が選択されるまで無効
                }
                .padding()
            }
        }
    }
}

#Preview {
    
}
