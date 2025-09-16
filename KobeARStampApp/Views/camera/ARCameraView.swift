//
//  camera.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

// ARCameraView.swift
import SwiftUI
import Combine // Combineフレームワークをインポート

// 写真データを複数のViewで共有・監視するためのクラス
class PhotoCollection: ObservableObject {
    @Published var assets: [PhotoAsset] = []
}

struct ARCameraView: View {

    @StateObject private var photoCollection = PhotoCollection()
    
    @State private var arScale: Float = 1.0
    @State private var isFlashOn = false
    @State private var selectedMode: CaptureMode = .photo
    @State private var showGuide = false
    @State private var showPhotoSelectionSheet = false
    @State private var showPreviewAndFilterSheet = false
    @State private var finalImage: UIImage?
    
    
    // シャッターボタンが押されたことをARViewContainerに伝えるための「トリガー」
    private let snapshotTrigger = PassthroughSubject<Void, Never>()
    

    enum CaptureMode: String {
        case video = "Video"
        case photo = "Photos"
    }

    var body: some View {
        ZStack {
            
            // ARViewContainerにトリガーと写真コレクションを渡す
            ARViewContainer(scale: $arScale,
                            snapshotTrigger: snapshotTrigger,
                            photoCollection: photoCollection)
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
        
        
        .onChange(of: photoCollection.assets.count) { newCount in
            guard newCount > 0 else { return }
            showPhotoSelectionSheet = true
        }
        
        .sheet(isPresented: $showPhotoSelectionSheet) {
            PhotoSelectionView(
                assets: $photoCollection.assets, // 参照先をphotoCollection.assetsに変更
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
        .sheet(isPresented: $showGuide) {
            // （使い方ガイドのコードは変更なし）
            VStack(alignment: .leading, spacing: 20) {
                // ...
            }
        }
    }

    // MARK: - UI Components
    
    
    @ViewBuilder
    private func topControls() -> some View {
        
        HStack {
            Button(action: { /* TODO: 閉じる処理 */ }) {
                Image(systemName: "xmark").font(.title2).foregroundColor(.white).frame(width: 44, height: 44).background(Color.black.opacity(0.5)).clipShape(Circle())
            }
            Spacer()
            Button(action: {
                isFlashOn.toggle()
                FlashlightManager.toggleFlash(on: isFlashOn)
            }) {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill").font(.title2).foregroundColor(isFlashOn ? .yellow : .white).frame(width: 44, height: 44).background(Color.black.opacity(0.5)).clipShape(Circle())
            }
            Spacer()
            Button(action: { showGuide = true }) {
                Image(systemName: "info.circle").font(.title2).foregroundColor(.white).frame(width: 44, height: 44).background(Color.black.opacity(0.5)).clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    @ViewBuilder
    private func bottomControls() -> some View {
        VStack(spacing: 20) {
            HStack(alignment: .center) {
                Button(action: {
                    if !photoCollection.assets.isEmpty { showPhotoSelectionSheet = true }
                }) {
                    ZStack(alignment: .topTrailing) {
                        if let lastAsset = photoCollection.assets.last {
                            Image(uiImage: lastAsset.image).resizable().scaledToFill().frame(width: 50, height: 50).clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                        } else {
                            Image(systemName: "photo.on.rectangle.angled").font(.system(size: 28)).foregroundColor(.white).frame(width: 50, height: 50)
                        }
                        if !photoCollection.assets.isEmpty {
                            Text("\(photoCollection.assets.count)").font(.caption2.bold()).foregroundColor(.white).padding(5).background(Color.red).clipShape(Circle()).offset(x: 5, y: -5)
                        }
                    }
                }.frame(width: 60)
                
                Spacer()
                
                
                // シャッターボタンのアクションをNotificationCenterからsnapshotTrigger.send()に変更
                Button(action: { snapshotTrigger.send() }) {
                    ZStack {
                        Circle().strokeBorder(Color.cyan.opacity(0.8), lineWidth: 4).frame(width: 80, height: 80)
                        Circle().fill(Color.white).frame(width: 68, height: 68)
                    }
                }
                

                Spacer()
                Button(action: { /* TODO: カメラ切り替え */ }) {
                    Image(systemName: "arrow.triangle.2.circlepath").font(.title2).foregroundColor(.white)
                }.frame(width: 60)
                
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)

            HStack(spacing: 20) {
                Button(CaptureMode.video.rawValue) { selectedMode = .video }.foregroundColor(selectedMode == .video ? .cyan : .white)
                Button(CaptureMode.photo.rawValue) { selectedMode = .photo }.foregroundColor(selectedMode == .photo ? .cyan : .white)
            }.font(.headline)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
    }
}






#Preview {
    ARCameraView()
}
