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
    @State private var filteredImageFromARView: UIImage? = nil

    var body: some View {
        ZStack {
            ARViewContainer(scale: $arScale)
                .ignoresSafeArea()

            if selectedFilter != "Normal", let previewImage = filteredImageFromARView {
                Image(uiImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 400)
                    .clipped()
                    .opacity(0.6)
                    .ignoresSafeArea()
            }

            VStack {
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

                HStack {
                    Spacer()
                    ARScaleSlider(arScale: $arScale)
                        .padding(.trailing, 4)
                        .padding(.bottom, 40)
                }

                VStack(spacing: 16) {
                    HStack {
                        Spacer()
                        Button(action: {
                            takeSnapshot()
                        }) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                        }
                        Spacer()
                    }

                    HStack {
                        Spacer()
                        Button(action: {
                            showFilter = true
                        }) {
                            ZStack {
                                Circle().stroke(Color.blue, lineWidth: 3)
                                    .frame(width: 38, height: 38)
                                Circle().stroke(Color.blue, lineWidth: 1)
                                    .frame(width: 24, height: 24)
                            }
                        }
                        .padding(.trailing, 16)

                        Button(action: { /* カメラ切替 */ }) {
                            Image(systemName: "camera.rotate")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 24)
                    }

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
        .onAppear {
            startLiveFilterPreview()
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

    func startLiveFilterPreview() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootVC = windowScene.windows.first?.rootViewController,
                  let arView = findARView(from: rootVC.view) else {
                return
            }

            arView.snapshot(saveToHDR: false) { image in
                if let img = image {
                    DispatchQueue.main.async {
                        let resized = resizeImage(image: img, targetSize: CGSize(width: 300, height: 400))
                        if selectedFilter == "Normal" {
                            self.filteredImageFromARView = nil
                        } else {
                            self.filteredImageFromARView = ARSnapshotManager.applyFilter(to: resized, filterName: selectedFilter)
                        }
                    }
                }
            }
        }
    }

    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }

    func findARView(from view: UIView) -> ARView? {
        if let arView = view as? ARView {
            return arView
        }
        for subview in view.subviews {
            if let found = findARView(from: subview) {
                return found
            }
        }
        return nil
    }
}




#Preview {
    ARCameraView()
}
