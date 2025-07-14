//
//  camera.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

// ARCameraView.swift
import SwiftUI

struct ARCameraView: View {
    // 状態変数
    @State private var arScale: Float = 1.0
    @State private var isFlashOn = false
    @State private var selectedMode: CaptureMode = .photo
    
    @State private var photoAssets: [PhotoAsset] = []
    @State private var showPhotoSelectionSheet = false
    @State private var showPreviewAndFilterSheet = false
    @State private var finalImage: UIImage?

    enum CaptureMode: String {
        case video = "Video"
        case photo = "Photos"
    }

    var body: some View {
        ZStack {
            ARViewContainer(scale: $arScale)
                .ignoresSafeArea()

            VStack {
                topControls()
                Spacer()
                HStack {
                    Spacer()
                    ARScaleSlider(arScale: $arScale)
                }
                .padding(.trailing, 10)
                Spacer()
                bottomControls()
            }
            .foregroundColor(.white)
        }
        .onReceive(NotificationCenter.default.publisher(for: .snapshotTaken)) { notification in
            if let image = notification.object as? UIImage {
                let newAsset = PhotoAsset(image: image)
                photoAssets.append(newAsset)
                showPhotoSelectionSheet = true
            }
        }
        .sheet(isPresented: $showPhotoSelectionSheet) {
            PhotoSelectionView(
                assets: $photoAssets,
                isPresented: $showPhotoSelectionSheet,
                onPhotoSelected: { selectedImage in
                    finalImage = selectedImage
                    showPhotoSelectionSheet = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        showPreviewAndFilterSheet = true
                    }
                }
            )
        }
        .sheet(isPresented: $showPreviewAndFilterSheet) {
            if let image = finalImage {
                PreviewAndFilterView(originalImage: image, isPresented: $showPreviewAndFilterSheet)
            }
        }
    }

    // MARK: - UI Components
    @ViewBuilder
    private func topControls() -> some View {
        HStack {
            Button(action: { /* TODO: 閉じる処理 */ }) {
                Image(systemName: "xmark").font(.title2).padding().background(Color.black.opacity(0.5)).clipShape(Circle())
            }
            Spacer()
            Button(action: { isFlashOn.toggle() /* TODO: フラッシュ制御 */ }) {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill").font(.title2).padding().background(Color.black.opacity(0.5)).clipShape(Circle())
            }
        }.padding(.horizontal).padding(.top, 50)
    }
    
    @ViewBuilder
    private func bottomControls() -> some View {
        VStack(spacing: 20) {
        
            HStack(alignment: .center) {
                Button(action: {
                    if !photoAssets.isEmpty { showPhotoSelectionSheet = true }
                }) {
                    ZStack(alignment: .topTrailing) {
                        if let lastAsset = photoAssets.last {
                            Image(uiImage: lastAsset.image)
                                .resizable().scaledToFill().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28)).foregroundColor(.white).frame(width: 50, height: 50)
                        }
                        if !photoAssets.isEmpty {
                            Text("\(photoAssets.count)")
                                .font(.caption2.bold()).foregroundColor(.white).padding(5).background(Color.red).clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                }.frame(width: 60)
                
                Spacer()
                Button(action: { NotificationCenter.default.post(name: .takeSnapshot, object: nil) }) {
                    ZStack {
                        Circle().strokeBorder(Color.white.opacity(0.8), lineWidth: 4).frame(width: 80, height: 80)
                        Circle().fill(Color.white).frame(width: 68, height: 68)
                    }
                }
                Spacer()
                Button(action: { /* TODO: カメラ切り替え */ }) {
                    Image(systemName: "arrow.triangle.2.circlepath.camera").font(.largeTitle)
                }.frame(width: 60)
            }
            .padding(.horizontal, 30) // この列の左右パディング

            
            HStack(spacing: 20) {
                Button(CaptureMode.video.rawValue) { selectedMode = .video }.foregroundColor(selectedMode == .video ? .yellow : .white)
                Button(CaptureMode.photo.rawValue) { selectedMode = .photo }.foregroundColor(selectedMode == .photo ? .yellow : .white)
            }.font(.headline)
        }
        .padding(.top, 20) // 上のシャッターボタンとの余白
        .padding(.bottom, 30) // 画面の底辺からの余白
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
    }
}





#Preview {
    ARCameraView()
}
