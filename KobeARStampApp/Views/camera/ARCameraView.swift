//
//  camera.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

// ARCameraView.swift
import SwiftUI
import Combine // Combineフレームワークをインポート
import CoreLocation

// 写真データを複数のViewで共有・監視するためのクラス
class PhotoCollection: ObservableObject {
    @Published var assets: [PhotoAsset] = []
}

struct ARCameraView: View {
    @StateObject private var photoCollection = PhotoCollection()
    
    let spot: Spot
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @Binding var activeTab: TabModel
    @ObservedObject var stampManager: StampManager
    
    @StateObject private var photoSaver = PhotoSaver()
    
    @State private var showSaveFeedbackAlert = false
    @State private var saveFeedbackMessage = ""
    
    @State private var arScale: Float = 1.0
    @State private var isFlashOn = false
    @State private var selectedMode: CaptureMode = .photo
    @State private var showGuide = false
    @State private var showPhotoSelectionSheet = false
    @State private var showPreviewAndFilterSheet = false
    @State private var finalImage: UIImage?
    @State private var selectableAssets: [PhotoAsset] = []
    @Environment(\.dismiss) private var dismiss
    
    // シャッターボタンが押されたことをARViewContainerに伝えるための「トリガー」
    private let snapshotTrigger = PassthroughSubject<Void, Never>()
    
    // 成功したアセットのみを返す計算プロパティ
    private var successfulAssets: [PhotoAsset] {
        photoCollection.assets.filter { asset in
            if case .success = asset.result { return true }
            return false
        }
    }

    enum CaptureMode: String {
        case video = "Video"
        case photo = "Photos"
    }

    var body: some View {
        ZStack {
            
            // ARViewContainerにトリガーと写真コレクションを渡す
            ARViewContainer(spot: spot, // Replace <#Spot#> with the actual `spot` variable
                                        scale: $arScale,
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
        
        
        .onChange(of: photoCollection.assets.count) {
                    guard let newAsset = photoCollection.assets.last else { return }
                    
                    switch newAsset.result {
                    case .success:
                        // If the capture is successful, show the photo selection sheet.
                        selectableAssets = successfulAssets
                        showPhotoSelectionSheet = true
                        
                    case .failure(let reason):
                        // If the capture fails, set the alert message and trigger the alert.
                        alertMessage = reason.localizedDescription
                        showAlert = true
                    }
                }
        .alert("撮影失敗", isPresented: $showAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(alertMessage)
                }
        
        .sheet(isPresented: $showPhotoSelectionSheet) {
            PhotoSelectionView(assets: $selectableAssets, isPresented: $showPhotoSelectionSheet) { selectedImage in
                            
                            // 1. スタンプカード用に内部保存
                            stampManager.addStamp(image: selectedImage, for: spot)
                            
                            // 2. デバイスのフォトライブラリに保存
                            photoSaver.saveImage(selectedImage)
                            
                        }
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
        .onReceive(photoSaver.$saveResult) { result in
                    guard let result = result else { return } // 新しい結果が来た時だけ実行
                    switch result {
                    case .success:
                        self.saveFeedbackMessage = "写真がフォトライブラリに保存されました！"
                    case .failure:
                        // ユーザーが「許可しない」を選んだ場合もここに来る
                        self.saveFeedbackMessage = "写真の保存に失敗しました。設定アプリで写真へのアクセスを許可してください。"
                    }
                    self.showSaveFeedbackAlert = true // 保存結果のアラートを表示
                    photoSaver.saveResult = nil // 結果をリセット
                }
                // 写真保存の結果を通知するアラート
                .alert("写真の保存", isPresented: $showSaveFeedbackAlert) {
                    Button("OK") {
                        // アラートのOKを押したら、スタンプカード画面に遷移、ここを変える
                        //activeTab = .stampRally
                        dismiss()
                    }
                } message: {
                    Text(saveFeedbackMessage)
                }
    }

    // MARK: - UI Components
    
    
    @ViewBuilder
    private func topControls() -> some View {
        // カメラを閉じる //
        HStack {
            Button(action: {
                dismiss()
            }) {
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
                
                Button(action: {
                   
                }) {
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
    let previewSpot = StampManager().allSpots.first ?? Spot(id: "preview-spot", name: "Preview Spot", placeholderImageName: "questionmark.circle", modelName: "box.usdz", coordinate: CLLocationCoordinate2D(latitude: 34.6901, longitude: 135.1955))
    
    // Corrected the argument order: activeTab must come before stampManager
    ARCameraView(spot: previewSpot,
                 activeTab: .constant(.home), // Moved activeTab before stampManager
                 stampManager: StampManager())
}

