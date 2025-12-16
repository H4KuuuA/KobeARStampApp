//
//  ARCameraView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import SwiftUI
import Combine

// 写真データを複数のViewで共有・監視するためのクラス
class PhotoCollection: ObservableObject {
    @Published var assets: [PhotoAsset] = []
}

struct ARCameraView: View {
    @StateObject private var photoCollection = PhotoCollection()
    @StateObject private var locationManager = LocationAwareCaptureManager()
    
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
            
            ARViewContainer(
                spot: spot,
                scale: $arScale,
                snapshotTrigger: snapshotTrigger,
                photoCollection: photoCollection
            )
            .ignoresSafeArea()
            

            VStack {
                topControls()
                
                // デバッグ表示（開発時のみ）
                #if DEBUG
                Text(locationManager.getStatusString())
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.black.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.top, 8)
                #endif
                
                Spacer()
                
                // 位置情報オーバーレイ
                locationInfoOverlay()

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
        .onAppear {
            // 位置情報の更新を開始（ProximityDetectorを使用）
            print("🎬 ARCameraView: onAppear - スポット: \(spot.name)")
            locationManager.updateNearestSpot(with: stampManager.allSpots)
            
            // 初期状態をログ出力
            print("📍 初期位置状態: \(locationManager.getStatusString())")
            print("📊 スタンプ管理状況: \(stampManager.acquiredStampCount)/\(stampManager.totalSpotCount)")
        }
        .onChange(of: locationManager.currentNearestSpot) { oldValue, newValue in
            // 最寄りスポットが変化した時
            if let spot = newValue {
                print("🎯 最寄りスポット変更: \(spot.name)")
                print("📏 距離: \(String(format: "%.1fm", locationManager.distanceToSpot))")
                print("✓ 撮影可能: \(locationManager.isWithinCaptureRange ? "YES" : "NO")")
            } else {
                print("❌ 最寄りスポットなし")
            }
        }
        .onChange(of: locationManager.isWithinCaptureRange) { oldValue, newValue in
            // 撮影可能状態が変化した時
            print("🚦 撮影可能状態変更: \(newValue ? "可能" : "不可")")
        }
        .onChange(of: photoCollection.assets.count) {
            guard let newAsset = photoCollection.assets.last else { return }
            
            switch newAsset.result {
            case .success:
                selectableAssets = successfulAssets
                showPhotoSelectionSheet = true
                
            case .failure(let reason):
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
                handlePhotoSelection(selectedImage)
            }
        }
        .sheet(isPresented: $showPreviewAndFilterSheet) {
            if let image = finalImage {
                PreviewAndFilterView(originalImage: image, isPresented: $showPreviewAndFilterSheet)
            }
        }
        .sheet(isPresented: $showGuide) {
            guideView()
        }
        .onReceive(photoSaver.$saveResult) { result in
            guard let result = result else { return }
            switch result {
            case .success:
                self.saveFeedbackMessage = "写真がフォトライブラリに保存されました！"
            case .failure:
                self.saveFeedbackMessage = "写真の保存に失敗しました。設定アプリで写真へのアクセスを許可してください。"
            }
            self.showSaveFeedbackAlert = true
            photoSaver.saveResult = nil
        }
        .alert("写真の保存", isPresented: $showSaveFeedbackAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(saveFeedbackMessage)
        }
    }
    
    // MARK: - Photo Selection Handler
    
    private func handlePhotoSelection(_ selectedImage: UIImage) {
        // ProximityDetectorベースの位置情報チェック
        // ⚠️ UUID型で判定
        let validation = locationManager.canCaptureStamp(for: spot.id)
        
        if !validation.canCapture {
            alertMessage = validation.message
            showAlert = true
            return
        }
        
        // 1. スタンプカード用に内部保存
        stampManager.addStamp(image: selectedImage, for: spot)
        
        // 2. デバイスのフォトライブラリに保存
        photoSaver.saveImage(selectedImage)
    }

    // MARK: - UI Components
    
    @ViewBuilder
    private func topControls() -> some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: {
                isFlashOn.toggle()
                FlashlightManager.toggleFlash(on: isFlashOn)
            }) {
                Image(systemName: isFlashOn ? "bolt.fill" : "bolt.slash.fill")
                    .font(.title2)
                    .foregroundColor(isFlashOn ? .yellow : .white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            Spacer()
            Button(action: { showGuide = true }) {
                Image(systemName: "info.circle")
                    .font(.title2)
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
        .padding(.top, 50)
    }
    
    // 位置情報オーバーレイ（ProximityDetectorベース）
    @ViewBuilder
    private func locationInfoOverlay() -> some View {
        if let nearestSpot = locationManager.currentNearestSpot {
            VStack(spacing: 8) {
                // ⚠️ UUID型で比較
                if locationManager.isWithinCaptureRange && nearestSpot.id == spot.id {
                    // ✅ 撮影可能エリア内（25m以内）
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("📍 \(nearestSpot.name)")
                            .font(.headline)
                    }
                    Text("撮影可能エリア")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        
                } else if nearestSpot.id == spot.id {
                    // ⚠️ 同じスポットだが範囲外
                    HStack(spacing: 6) {
                        Image(systemName: "location.circle")
                            .foregroundColor(.orange)
                        Text("📍 \(nearestSpot.name)")
                            .font(.headline)
                    }
                    Text("もう少し近づいてください (\(String(format: "%.0fm", locationManager.distanceToSpot)))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                        
                } else {
                    // ❌ 別のスポットが近い
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                        Text("⚠️ 別のスポット: \(nearestSpot.name)")
                            .font(.headline)
                    }
                    Text("このスポットではスタンプを取得できません")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.75))
            )
            .padding(.bottom, 10)
        }
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
                            Image(uiImage: lastAsset.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white, lineWidth: 1))
                        } else {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                        }
                        if !photoCollection.assets.isEmpty {
                            Text("\(photoCollection.assets.count)")
                                .font(.caption2.bold())
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 5, y: -5)
                        }
                    }
                }
                .frame(width: 60)
                
                Spacer()
                
                // シャッターボタン（ProximityDetectorの判定結果で色を変更）
                // ⚠️ UUID型で比較
                Button(action: { snapshotTrigger.send() }) {
                    ZStack {
                        Circle()
                            .strokeBorder(
                                locationManager.isWithinCaptureRange && locationManager.currentNearestSpot?.id == spot.id
                                    ? Color.green.opacity(0.8)  // 撮影可能: 緑
                                    : Color.cyan.opacity(0.8),  // それ以外: シアン
                                lineWidth: 4
                            )
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 68, height: 68)
                    }
                }
                
                Spacer()
                
                Button(action: {}) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(width: 60)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 20)

            HStack(spacing: 20) {
                Button(CaptureMode.video.rawValue) { selectedMode = .video }
                    .foregroundColor(selectedMode == .video ? .cyan : .white)
                Button(CaptureMode.photo.rawValue) { selectedMode = .photo }
                    .foregroundColor(selectedMode == .photo ? .cyan : .white)
            }
            .font(.headline)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.3))
    }
    
    // 使い方ガイド
    @ViewBuilder
    private func guideView() -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("使い方ガイド")
                .font(.title.bold())
            
            Text("1. スタンプポイントに近づく（25m以内）")
            Text("2. 画面上部に「撮影可能エリア」と表示される")
            Text("3. ARモデルを配置してシャッターボタンを押す")
            Text("4. 写真を選択すると位置検証が行われます")
            Text("5. スタンプが自動的に保存されます")
            
            Spacer()
            
            Button("閉じる") {
                showGuide = false
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

#Preview {
    let previewSpot = Spot.testSpot
    
    ARCameraView(
        spot: previewSpot,
        activeTab: .constant(.home),
        stampManager: StampManager()
    )
}
