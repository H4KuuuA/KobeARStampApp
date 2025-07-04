//
//  camera.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

// ARCameraView.swift
import SwiftUI
import RealityKit
import ARKit

struct ARCameraView: View {
    @State private var arScale: Float = 1.0
    @State private var showGuide = false
    @State private var showFilter = false
    @State private var selectedMode: String = "Photo"
    @State private var capturedImage: UIImage? = nil
    @State private var savedImageURL: URL? = nil
    @State private var showPreview = false
    @State private var selectedFilter: String = "CIPhotoEffectNoir"
    @State private var filteredImage: UIImage = UIImage()

    var body: some View {
        ZStack {
            ARViewContainer(scale: $arScale)
                .ignoresSafeArea()

            VStack {
                // 上部ボタン群
                HStack {
                    Button(action: { /* 戻る処理 */ }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24))
                            .padding()
                    }
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: { /* フラッシュ切替 */ }) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 24))
                        }
                        Button(action: { showGuide = true }) {
                            Image(systemName: "questionmark.circle")
                                .font(.system(size: 24))
                        }
                    }
                    .padding(.trailing, 16)
                }

                Spacer()

                // 右スライダー
                HStack {
                    Spacer()
                    ARScaleSlider(arScale: $arScale)
                        .padding(.trailing, 2)
                        .padding(.bottom, 40)
                }

                // 下部UI
                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Button(action: {
                            takeSnapshot()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Circle().stroke(Color.gray, lineWidth: 2)
                                )
                        }
                        Spacer()
                    }

                    // フィルターアイコン & カメラ切替
                    HStack {
                        Spacer()

                        Button(action: {
                            showFilter = true
                        }) {
                            ZStack {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                Circle()
                                    .stroke(Color.blue, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.trailing, 16)

                        Button(action: { /* カメラ切替（非対応） */ }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 24)
                    }

                    // モード切替（画面下沿い）
                    Picker(selection: $selectedMode, label: Text("")) {
                        Text("Video").tag("Video")
                        Text("Photo").tag("Photo")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 160)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Capsule())
                    .padding(.bottom, 12)
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            Text("ARカメラの使い方ガイド").padding()
        }
        .sheet(isPresented: $showPreview) {
            if let image = capturedImage {
                VStack {
                    Image(uiImage: filteredImage)
                        .resizable()
                        .scaledToFit()
                        .padding()

                    Button("カメラロールに保存") {
                        UIImageWriteToSavedPhotosAlbum(filteredImage, nil, nil, nil)
                        showPreview = false
                    }
                    .padding()

                    Button("閉じる") {
                        showPreview = false
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showFilter) {
            if let captured = capturedImage {
                FilterSelectionView(
                    originalImage: captured,
                    selectedFilter: $selectedFilter,
                    filteredImage: $filteredImage
                )
            } else {
                Text("画像がありません")
            }
        }
    }

    func takeSnapshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }

        ARSnapshotManager.takeSnapshot(from: rootVC.view) { image in
            if let uiImage = image {
                let filtered = ARSnapshotManager.applyFilter(to: uiImage, filterName: selectedFilter)
                self.capturedImage = uiImage
                self.filteredImage = filtered
                self.savedImageURL = ARSnapshotManager.saveImageToAppDirectory(image: filtered)
                self.showPreview = true
            }
        }
    }
}




#Preview {
    ARCameraView()
}
