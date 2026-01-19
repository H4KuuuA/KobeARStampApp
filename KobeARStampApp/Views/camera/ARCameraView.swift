//
//  ARCameraView.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import SwiftUI
import Combine
import CoreLocation

// 写真データを複数のViewで共有・監視するためのクラス
class PhotoCollection: ObservableObject {
    @Published var assets: [PhotoAsset] = []
}

struct ARCameraView: View {
    @StateObject private var photoCollection = PhotoCollection()
    @StateObject private var locationManager = LocationManager.shared
    private let proximityDetector = ProximityDetector()
    
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
    
    // 位置情報の状態管理
    @State private var distanceToSpot: CLLocationDistance = 0
    @State private var isWithinRange: Bool = false
    @State private var cancellables = Set<AnyCancellable>()
    
    // ARModel取得用
    @State private var arModel: ARModel? = nil
    @State private var isLoadingModel = false
    
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
            
            // ARModelをARViewContainerに渡す（デバッグログ追加）
            let _ = print("🔄 ARCameraView body評価 - arModel: \(arModel?.modelName ?? "nil")")
            
            ARViewContainer(
                spot: spot,
                arModel: arModel,  // DBから取得したモデルを渡す
                scale: $arScale,
                snapshotTrigger: snapshotTrigger,
                photoCollection: photoCollection
            )
            .ignoresSafeArea()
            

            VStack {
                topControls()
                
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
            // 位置情報の更新を開始
            print("🎬 ARCameraView: onAppear - スポット: \(spot.name)")
            setupLocationMonitoring()
            updateDistance()
            
            // DBからARModelを取得
            loadARModel()
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
            PhotoSelectionView(
                assets: selectableAssets,
                isPresented: $showPhotoSelectionSheet,
                onPhotoSelected: { selectedImage in
                    handlePhotoSelection(selectedImage)
                },
                onRetake: {
                    // Dismiss the selection sheet and allow the user to retake
                    showPhotoSelectionSheet = false
                    // Optionally clear the last unsuccessful capture attempt if needed
                    // Keep successful assets list consistent
                    selectableAssets = successfulAssets
                }
            )
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
                self.saveFeedbackMessage = "写真がフォトライブラリに保存されました!"
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
    
    // MARK: - Location Monitoring
    
    /// DBからARModelを取得
    private func loadARModel() {
        // spot.arModelIdが存在する場合のみDB取得を試みる
        guard let arModelId = spot.arModelId else {
            print("⚠️ スポット \(spot.name) にはarModelIdが設定されていません。デフォルトモデルを使用します。")
            return
        }
        
        isLoadingModel = true
        print("🔄 ARModel読み込み開始: ID=\(arModelId)")
        
        Task {
            do {
                if let fetchedModel = try await DataRepository.shared.fetchArModel(for: spot) {
                    await MainActor.run {
                        self.arModel = fetchedModel
                        self.isLoadingModel = false
                        print("✅ ARModel取得成功: \(fetchedModel.modelName)")
                        print("   - ファイルURL: \(fetchedModel.fileUrl)")
                        print("   - ファイルタイプ: \(fetchedModel.fileType ?? "不明")")
                        print("   - ファイルサイズ: \(fetchedModel.displayFileSize)")
                    }
                } else {
                    await MainActor.run {
                        self.isLoadingModel = false
                        print("⚠️ ARModelが見つかりませんでした。デフォルトモデルを使用します。")
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoadingModel = false
                    print("❌ ARModel取得エラー: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func setupLocationMonitoring() {
        locationManager.$latitude
            .combineLatest(locationManager.$longitude)
            .dropFirst()
            .debounce(for: .milliseconds(500), scheduler: DispatchQueue.main)
            .sink { [self] _, _ in
                updateDistance()
            }
            .store(in: &cancellables)
    }
    
    /// 現在地からスポットまでの距離を計算
    private func updateDistance() {
        guard locationManager.latitude != 0.0, locationManager.longitude != 0.0 else {
            distanceToSpot = 0
            isWithinRange = false
            return
        }
        
        let currentLocation = CLLocation(
            latitude: locationManager.latitude,
            longitude: locationManager.longitude
        )
        
        let spotLocation = CLLocation(
            latitude: spot.latitude,
            longitude: spot.longitude
        )
        
        distanceToSpot = currentLocation.distance(from: spotLocation)
        isWithinRange = distanceToSpot <= 25.0
        
        print("📍 \(spot.name)まで: \(String(format: "%.1fm", distanceToSpot)) - \(isWithinRange ? "✅圏内" : "❌圏外")")
    }
    
    /// スタンプ取得可能か判定
    private func canCaptureStamp() -> (canCapture: Bool, message: String) {
        guard locationManager.latitude != 0.0, locationManager.longitude != 0.0 else {
            return (false, "位置情報を取得できません")
        }
        
        guard isWithinRange else {
            let distance = String(format: "%.0f", distanceToSpot)
            return (false, "\(spot.name)まであと\(distance)mです")
        }
        
        return (true, "スタンプを取得しました！")
    }
    
    // MARK: - Photo Selection Handler
    
    private func handlePhotoSelection(_ selectedImage: UIImage) {
        // 位置情報チェック
        let validation = canCaptureStamp()
        
        if !validation.canCapture {
            alertMessage = validation.message
            showAlert = true
            return
        }
        
        // アプリディレクトリ + フォトライブラリの両方に保存
        photoSaver.saveImage(selectedImage, for: spot)
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
    
    // 位置情報オーバーレイ
    @ViewBuilder
    private func locationInfoOverlay() -> some View {
        VStack(spacing: 8) {
            if isWithinRange {
                // ✅ 撮影可能エリア内（25m以内）
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("📍 \(spot.name)")
                        .font(.headline)
                }
                Text("撮影可能エリア")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.9))
                    
            } else {
                // ⚠️ 範囲外
                HStack(spacing: 6) {
                    Image(systemName: "location.circle")
                        .foregroundColor(.orange)
                    Text("📍 \(spot.name)")
                        .font(.headline)
                }
                Text("もう少し近づいてください (\(String(format: "%.0fm", distanceToSpot)))")
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
                
                // シャッターボタン
                Button(action: { snapshotTrigger.send() }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.cyan.opacity(0.8), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        Circle()
                            .fill(Color.white)
                            .frame(width: 68, height: 68)
                    }
                }
                
                Spacer()
                
                Color.clear
                    .frame(width: 60)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 6)
            .padding(.top, 10)
            .background(Color.black.opacity(0.3))
            .offset(y:20)
        }
        .padding(.top, 80)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
        
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
        stampManager: StampManager.shared
    )
}
