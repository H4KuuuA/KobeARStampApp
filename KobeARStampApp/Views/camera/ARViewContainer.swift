//
//  ARViewContainer.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct ARViewContainer: UIViewRepresentable {
    
    let spot: Spot
    let arModel: ARModel?  // ✅ オプショナルで受け取る
    
    @Binding var scale: Float
    let snapshotTrigger: PassthroughSubject<Void, Never>
    @ObservedObject var photoCollection: PhotoCollection

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
        
        // MARK: - People Occlusion Implementation
        // デバイスがピープルオクルージョン（深度付き人物セグメンテーション）をサポートしているか確認し、有効化します
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            config.frameSemantics.insert(.personSegmentationWithDepth)
        }
        
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.subscribeToActionStream()
        
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateScale(scale)
        // arModelを更新
        context.coordinator.arModel = arModel
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(spot: spot, arModel: arModel, snapshotTrigger: snapshotTrigger, photoCollection: photoCollection)
    }

    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        weak var arView: ARView?
        var cancellables = Set<AnyCancellable>()
        private var lastPlacedAnchor: AnchorEntity?
        private var loadTask: Task<Void, Never>?
        
        let spot: Spot
        var arModel: ARModel?  // ✅ varに変更（更新可能にする）
        
        // UIのスライダー値（updateScaleで使用）
        var currentScale: Float = 1.0
        
        // ==========================================
        // 🛠️ 調整用パラメータ（ここをいじって調整してください）
        // ==========================================
        // モデルが勝手に100倍になる場合、ここを 0.01 にする
        private let baseCorrectionScale: Float = 0.1
        
        // モデルが浮く場合、ここをマイナスにする（例: -0.15 で15cm下がる）
        private let yAxisCorrectionOffset: Float = 0.0 // まずは0で試し、浮くようなら -0.5 等に変更
        // ==========================================

        let snapshotTrigger: PassthroughSubject<Void, Never>
        let photoCollection: PhotoCollection
        
        // モデルの種類を定義
        enum ModelKind {
            case usdz
            case reality
            case other
        }

        init(spot: Spot, arModel: ARModel?, snapshotTrigger: PassthroughSubject<Void, Never>, photoCollection: PhotoCollection) {
            self.spot = spot
            self.arModel = arModel
            self.snapshotTrigger = snapshotTrigger
            self.photoCollection = photoCollection
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            print("👆 タップ検知")
            
            guard let arView = arView,
                  let query = arView.makeRaycastQuery(from: recognizer.location(in: arView), allowing: .estimatedPlane, alignment: .horizontal),
                  let firstResult = arView.session.raycast(query).first else {
                print("⚠️ レイキャスト失敗")
                return
            }
            
            print("✅ レイキャスト成功 - モデル配置開始")

            // 1. Cancel previous loading task if any
            loadTask?.cancel()

            // 2. Remove previous anchor (clear previous stamp)
            if let oldAnchor = lastPlacedAnchor {
                arView.scene.removeAnchor(oldAnchor)
                print("🗑️ 前のアンカー削除")
            }

            // 3. Create and add a new anchor
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            arView.scene.addAnchor(anchor)
            lastPlacedAnchor = anchor
            print("📍 新しいアンカー配置")

            // Ghost while loading
            let ghostSphere = try? MeshResource.generateSphere(radius: 0.05)
            let ghostMaterial = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.3))
            let ghostEntity = ModelEntity(mesh: ghostSphere ?? MeshResource.generateBox(size: 0.1), materials: [ghostMaterial])
            anchor.addChild(ghostEntity)
            print("👻 ゴースト表示")

            // 4. Start a new cancellable loading task and keep a reference
            loadTask = Task { [weak self] in
                print("🚀 モデル読み込みTask開始")
                guard let self = self else { return }

                if Task.isCancelled { return }

                do {
                    print("🔍 モデルURL解決開始")
                    
                    // (中略) URL解決ロジックは変更なし
                    // ...
                    
                    // ✅ Resolve model URL
                    let sourceURL: URL
                    let modelKind: ModelKind
                    
                    if let arModel = self.arModel {
                        let localURL = await ARModelManager.shared.localURL(for: arModel.id)
                        let fileExists = await MainActor.run { FileManager.default.fileExists(atPath: localURL.path) }
                        
                        if fileExists {
                            sourceURL = localURL
                        } else if let remoteURL = arModel.fileURL {
                            sourceURL = remoteURL
                        } else {
                            throw URLError(.badURL)
                        }
                        
                        if arModel.isUSDZ { modelKind = .usdz }
                        else if arModel.isReality { modelKind = .reality }
                        else { modelKind = .other }
                        
                    } else if let url = URL(string: self.spot.modelName), url.scheme != nil {
                        sourceURL = url
                        modelKind = .usdz
                    } else {
                        let fileName = self.spot.modelName.replacingOccurrences(of: ".usdz", with: "")
                        guard let bundleURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
                            throw URLError(.fileDoesNotExist)
                        }
                        sourceURL = bundleURL
                        modelKind = .usdz
                    }

                    // Download logic (abbreviated for clarity, keeping original logic)
                    let finalURL: URL
                    if sourceURL.isFileURL {
                        finalURL = sourceURL
                    } else {
                        let (data, _) = try await URLSession.shared.data(from: sourceURL)
                        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                        let fileExtension = modelKind == .reality ? "reality" : "usdz"
                        let tempURL = caches.appendingPathComponent("temp_ar_\(UUID().uuidString).\(fileExtension)")
                        try data.write(to: tempURL)
                        finalURL = tempURL
                    }
                    
                    if Task.isCancelled { return }

                    // Load ModelEntity
                    let loadedEntity: Entity
                    switch modelKind {
                    case .usdz:
                        loadedEntity = try await ModelEntity.load(contentsOf: finalURL)
                    case .reality:
                        loadedEntity = try await Entity.load(contentsOf: finalURL)
                    case .other:
                        loadedEntity = try await ModelEntity.load(contentsOf: finalURL)
                    }
                    
                    loadedEntity.generateCollisionShapes(recursive: true)
                    if Task.isCancelled { return }

                    // Update UI only if this anchor is still the latest
                    await MainActor.run {
                        guard self.lastPlacedAnchor == anchor else { return }
                        ghostEntity.removeFromParent()
                        
                        // ==========================================
                        // 🛠️ 修正: コンテナパターンによる配置
                        // ==========================================
                        
                        // 1. 調整用の「親（コンテナ）」を作成
                        let modelContainer = Entity()
                        
                        // 2. 読み込んだモデルをコンテナの子にする
                        modelContainer.addChild(loadedEntity)
                        
                        // 3. アニメーションによる上書きを防ぐため、モデル自体のスケールはリセット
                        // (アニメーションデータがここを1.0などに書き換えてくるため)
                        loadedEntity.scale = SIMD3<Float>(repeating: 1.0)
                        loadedEntity.position = SIMD3<Float>(repeating: 0.0)
                        
                        // 4. 【巨大化対策】コンテナ側で基本サイズを小さくする
                        // ユーザーのスライダー値(currentScale)と、ベース補正値(0.01等)を掛け合わせる
                        let finalScale = self.baseCorrectionScale * self.currentScale
                        modelContainer.scale = SIMD3<Float>(repeating: finalScale)
                        
                        // 5. 【宙に浮く対策】コンテナ側で位置を下げる
                        modelContainer.position.y = self.yAxisCorrectionOffset

                        // 6. アンカーに追加するのは「モデル」ではなく「コンテナ」
                        anchor.addChild(modelContainer)

                        // 7. アニメーション再生（再帰的に検索してすべて再生）
                        print("🎬 アニメーション再生開始")
                        loadedEntity.availableAnimations.forEach { animation in
                            loadedEntity.playAnimation(animation.repeat())
                        }

                        print("✅ モデル配置完了 (コンテナ経由)")
                        print("   - ベース補正: \(self.baseCorrectionScale)")
                        print("   - Y軸オフセット: \(self.yAxisCorrectionOffset)")
                    }
                } catch {
                    if Task.isCancelled { return }
                    print("❌ モデル読み込み失敗: \(error.localizedDescription)")
                    await MainActor.run {
                        guard self.lastPlacedAnchor == anchor else { return }
                        ghostEntity.removeFromParent()
                        // Fallback logic remains same
                    }
                }
            }
        }
        
        func subscribeToActionStream() {
            snapshotTrigger
                .sink { [weak self] in
                    self?.takeSnapshot()
                }
                .store(in: &cancellables)
        }

        func takeSnapshot() {
            guard let arView = arView else { return }
            // (Capture logic remains same)
            // Note: checkCaptureCondition uses lastPlacedAnchor, which is still valid
            // ...
            arView.snapshot(saveToHDR: false) { [weak self] image in
                DispatchQueue.main.async {
                     guard let self = self, let capturedImage = image else { return }
                     let newAsset = PhotoAsset(image: capturedImage, result: self.checkCaptureCondition(arView: arView))
                     self.photoCollection.assets.append(newAsset)
                }
            }
        }
        
        private func checkCaptureCondition(arView: ARView) -> Result<Void, CaptureFailureReason> {
            // lastPlacedAnchorはコンテナをぶら下げている親アンカーなので、位置判定にはそのまま使えます
            guard let anchor = lastPlacedAnchor else { return .failure(.noModelPlaced) }
            
            guard let projectedPoint = arView.project(anchor.position(relativeTo: nil)) else {
                return .failure(.modelNotInView)
            }
            
            if arView.bounds.contains(projectedPoint) {
                return .success(())
            } else {
                return .failure(.modelNotInView)
            }
        }

        func updateScale(_ newScale: Float) {
            self.currentScale = newScale // 現在値を保持
            
            guard let anchor = lastPlacedAnchor else {
                print("⚠️ スケール更新: アンカーなし")
                return
            }
            
            // アンカーの直下にあるのは「コンテナ」
            if let container = anchor.children.first {
                
                // 【重要】スライダーの値にも「ベース補正値」を掛ける
                let finalScale = baseCorrectionScale * newScale
                
                container.setScale(SIMD3<Float>(repeating: finalScale), relativeTo: nil)
                print("📏 コンテナスケール更新: \(finalScale) (入力: \(newScale))")
            } else {
                print("⚠️ スケール更新: モデル未配置")
            }
        }
    }
}
