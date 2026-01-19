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
                    print("   - arModel状態: \(self.arModel?.modelName ?? "nil")")
                    
                    // ✅ Resolve model URL - ローカルファイル優先、なければネットワークから取得
                    let sourceURL: URL
                    let modelKind: ModelKind
                    
                    if let arModel = self.arModel {
                        print("📦 DBモデル使用: \(arModel.modelName)")
                        print("   - arModel.id: \(arModel.id)")
                        
                        // DBから取得したARModelを使用
                        
                        // 1. まずローカルに保存済みか確認（ARModelManager経由）
                        let localURL = await ARModelManager.shared.localURL(for: arModel.id)
                        print("   - ローカルURL: \(localURL.path)")
                        
                        let fileExists = await MainActor.run {
                            let exists = FileManager.default.fileExists(atPath: localURL.path)
                            print("   - ファイル存在チェック: \(exists ? "存在する" : "存在しない")")
                            return exists
                        }
                        
                        if fileExists {
                            sourceURL = localURL
                            print("✅ ローカルキャッシュ使用")
                        } else if let remoteURL = arModel.fileURL {
                            // 2. ローカルになければネットワークから取得
                            sourceURL = remoteURL
                            print("⚠️ ローカルファイル未検出 - ネットワークから取得")
                            print("   - リモートURL: \(remoteURL)")
                        } else {
                            print("❌ URL取得失敗: \(arModel.fileUrl)")
                            throw URLError(.badURL)
                        }
                        
                        // ファイル拡張子から種類を判定
                        if arModel.isUSDZ {
                            modelKind = .usdz
                        } else if arModel.isReality {
                            modelKind = .reality
                        } else {
                            modelKind = .other
                        }
                        
                        print("   - モデル種類: \(modelKind)")
                    } else if let url = URL(string: self.spot.modelName), url.scheme != nil {
                        // Spot.modelNameがURL形式の場合
                        sourceURL = url
                        modelKind = .usdz // デフォルトでUSDZとして扱う
                        print("⚠️ Spot.modelName(URL)使用: \(self.spot.modelName)")
                    } else {
                        // Spot.modelNameがファイル名のみの場合（Bundle内を探す）
                        let fileName = self.spot.modelName.replacingOccurrences(of: ".usdz", with: "")
                        guard let bundleURL = Bundle.main.url(forResource: fileName, withExtension: "usdz") else {
                            print("❌ Bundleにファイルが見つかりません: \(fileName)")
                            throw URLError(.fileDoesNotExist)
                        }
                        sourceURL = bundleURL
                        modelKind = .usdz
                        print("⚠️ Bundleモデル使用: \(fileName).usdz")
                    }

                    // ローカルファイルから直接読み込む場合とネットワークから取得する場合で処理を分岐
                    let finalURL: URL
                    
                    if sourceURL.isFileURL {
                        // ローカルファイルはそのまま使用
                        print("📂 ローカルファイルから読み込み: \(sourceURL.lastPathComponent)")
                        finalURL = sourceURL
                    } else {
                        // ネットワークからダウンロードしてCachesに保存
                        print("🌐 ネットワークダウンロード中...")
                        let (data, response) = try await URLSession.shared.data(from: sourceURL)
                        
                        // HTTPレスポンスを確認
                        if let httpResponse = response as? HTTPURLResponse {
                            print("   - HTTPステータス: \(httpResponse.statusCode)")
                            if httpResponse.statusCode == 404 {
                                throw URLError(.fileDoesNotExist)
                            }
                        }
                        
                        print("✅ ダウンロード完了: \(data.count) bytes")
                        
                        if Task.isCancelled { return }
                        
                        // Cachesディレクトリに一時保存
                        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                        let fileExtension = modelKind == .reality ? "reality" : "usdz"
                        let tempURL = caches.appendingPathComponent("temp_ar_\(UUID().uuidString).\(fileExtension)")
                        try data.write(to: tempURL)
                        print("💾 一時保存: \(tempURL.lastPathComponent)")
                        
                        finalURL = tempURL
                    }
                    
                    if Task.isCancelled { return }

                    // Load ModelEntity or Entity from local file depending on model kind
                    print("🔄 RealityKit読み込み中: \(finalURL.lastPathComponent)")
                    let loadedEntity: Entity
                    switch modelKind {
                    case .usdz:
                        loadedEntity = try await ModelEntity.load(contentsOf: finalURL)
                    case .reality:
                        loadedEntity = try await Entity.load(contentsOf: finalURL)
                    case .other:
                        // Fallback: try as USDZ first
                        loadedEntity = try await ModelEntity.load(contentsOf: finalURL)
                    }
                    
                    // デバッグ: モデル情報を出力
                    print("📊 読み込んだモデル情報:")
                    print("   - 子エンティティ数: \(loadedEntity.children.count)")
                    if let modelEntity = loadedEntity as? ModelEntity {
                        print("   - モデルあり: \(modelEntity.model != nil)")
                        if let model = modelEntity.model {
                            print("   - メッシュ数: \(model.mesh.contents.models.count)")
                        }
                    }
                    print("   - バウンディングボックス: \(loadedEntity.visualBounds(relativeTo: nil))")
                    
                    // スケールを設定（見やすいサイズに）
                    loadedEntity.scale = SIMD3<Float>(repeating: 0.1)  // デフォルトで小さめに
                    
                    loadedEntity.generateCollisionShapes(recursive: true)
                    if Task.isCancelled { return }

                    // Update UI only if this anchor is still the latest
                    await MainActor.run {
                        guard self.lastPlacedAnchor == anchor else { return }
                        ghostEntity.removeFromParent()
                        anchor.addChild(loadedEntity)
                        print("✅ モデル配置完了")
                        print("   - アンカー位置: \(anchor.position(relativeTo: nil))")
                        print("   - 子エンティティ数: \(anchor.children.count)")
                    }
                } catch {
                    if Task.isCancelled { return }
                    print("❌ モデル読み込み失敗: \(error.localizedDescription)")
                    await MainActor.run {
                        guard self.lastPlacedAnchor == anchor else { return }
                        ghostEntity.removeFromParent()
                        let box = MeshResource.generateBox(size: 0.1)
                        let material = SimpleMaterial(color: .systemPink, isMetallic: true)
                        let fallback = ModelEntity(mesh: box, materials: [material])
                        fallback.generateCollisionShapes(recursive: true)
                        anchor.addChild(fallback)
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
            guard let arView = arView else {
                print("❌ 撮影失敗: ARViewなし")
                return
            }
            
            print("📸 スナップショット開始")
            
            let captureResult = checkCaptureCondition(arView: arView)

            arView.snapshot(saveToHDR: false) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self = self, let capturedImage = image else {
                        print("❌ スナップショット取得失敗")
                        return
                    }
                    
                    print("✅ スナップショット取得成功")
                    
                    let newAsset = PhotoAsset(image: capturedImage, result: captureResult)
                    self.photoCollection.assets.append(newAsset)
                    
                    print("📦 PhotoAsset追加: 結果=\(captureResult)")
                }
            }
        }
        
        private func checkCaptureCondition(arView: ARView) -> Result<Void, CaptureFailureReason> {
            guard let model = lastPlacedAnchor else {
                print("📸 撮影判定: モデル未配置")
                return .failure(.noModelPlaced)
            }
            
            guard let projectedPoint = arView.project(model.position(relativeTo: nil)) else {
                print("📸 撮影判定: プロジェクション失敗")
                return .failure(.modelNotInView)
            }
            
            let isInBounds = arView.bounds.contains(projectedPoint)
            print("📸 撮影判定:")
            print("   - プロジェクト座標: \(projectedPoint)")
            print("   - ARView範囲: \(arView.bounds)")
            print("   - 範囲内: \(isInBounds)")
            
            if isInBounds {
                print("✅ 撮影条件OK")
                return .success(())
            } else {
                print("❌ モデルが画面外")
                return .failure(.modelNotInView)
            }
        }

        func updateScale(_ newScale: Float) {
            guard let anchor = lastPlacedAnchor else {
                print("⚠️ スケール更新: アンカーなし")
                return
            }
            anchor.setScale(SIMD3<Float>(repeating: newScale), relativeTo: nil)
            print("📏 スケール更新: \(newScale)")
        }
    }
}
