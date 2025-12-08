//
//  PhotoSelectionView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import SwiftUI

struct PhotoSelectionView: View {
    // 親Viewから受け取る写真リスト
    let assets: [PhotoAsset]
    
    // シートを閉じるためのBinding
    @Binding var isPresented: Bool
    
    // 決定時のアクション
    var onPhotoSelected: (UIImage) -> Void
    
    // 撮り直し（削除）時のアクション
    var onRetake: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // --- 写真表示エリア ---
            // スペースを使って写真を中央に配置しつつ、ボタンエリアを確保
            Spacer()
            
            if let asset = assets.last {
                Image(uiImage: asset.image)
                    .resizable()
                    .scaledToFit() // アスペクト比を維持して全体を表示（端が見切れない）
                    .frame(maxWidth: .infinity) // 横幅いっぱいに
                    .clipped()
            } else {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                    Text("写真がありません")
                }
                .foregroundColor(.gray)
            }
            
            Spacer()
            
            // --- 操作ボタンエリア ---
            HStack(spacing: 24) {
                // 撮り直すボタン
                Button(action: {
                    onRetake() // 削除処理
                    isPresented = false
                }) {
                    Text("撮り直す")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.5)) // 少し控えめな色
                        .cornerRadius(30)
                }
                
                // この写真にするボタン
                Button(action: {
                    if let asset = assets.last {
                        onPhotoSelected(asset.image)
                    }
                }) {
                    Text("この写真にする")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.cyan) // 強調色
                        .cornerRadius(30)
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 40) // 下に余裕を持たせる
            .background(Color.black) // ボタンエリアの背景も黒
        }
        .background(Color.black.ignoresSafeArea()) // 画面全体の背景を黒に
    }
}
