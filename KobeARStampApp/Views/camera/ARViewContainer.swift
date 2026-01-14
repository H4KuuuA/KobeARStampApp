//
//  ARViewContainer.swift.swift
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
    let arModel: ARModel?
    
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
        let arModel: ARModel?
        
        let snapshotTrigger: PassthroughSubject<Void, Never>
        let photoCollection: PhotoCollection

        init(spot: Spot, arModel: ARModel?, snapshotTrigger: PassthroughSubject<Void, Never>, photoCollection: PhotoCollection) {
            self.spot = spot
            self.arModel = arModel
            self.snapshotTrigger = snapshotTrigger
            self.photoCollection = photoCollection
        }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView,
                  let query = arView.makeRaycastQuery(from: recognizer.location(in: arView), allowing: .estimatedPlane, alignment: .horizontal),
                  let firstResult = arView.session.raycast(query).first else {
                return
            }

            // 1. Cancel previous loading task if any
            loadTask?.cancel()

            // 2. Remove previous anchor (clear previous stamp)
            if let oldAnchor = lastPlacedAnchor {
                arView.scene.removeAnchor(oldAnchor)
            }

            // 3. Create and add a new anchor
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            arView.scene.addAnchor(anchor)
            lastPlacedAnchor = anchor

            // Ghost while loading
            let ghostSphere = try? MeshResource.generateSphere(radius: 0.05)
            let ghostMaterial = UnlitMaterial(color: UIColor.white.withAlphaComponent(0.3))
            let ghostEntity = ModelEntity(mesh: ghostSphere ?? MeshResource.generateBox(size: 0.1), materials: [ghostMaterial])
            anchor.addChild(ghostEntity)

            // 4. Start a new cancellable loading task and keep a reference
            loadTask = Task { [weak self] in
                guard let self = self else { return }

                if Task.isCancelled { return }

                do {
                    // Prefer local file if arModelId is available and synced via ARModelManager
                    var data: Data
                    if let modelId = self.spot.arModelId, await ARModelManager.shared.modelExists(modelId: modelId) {
                        let localURL = await ARModelManager.shared.localURL(for: modelId)
                        print("📦 Loading local USDZ from: \(localURL.path)")
                        data = try Data(contentsOf: localURL)
                    } else {
                        // Otherwise resolve from ARModel (remote URL). This path expects a valid HTTPS URL.
                        let sourceURL: URL
                        if let arModel = self.arModel, let url = arModel.fileURL {
                            sourceURL = url
                        } else if let arModelId = self.spot.arModelId {
                            // If we only have the ID but no ARModel object, fail explicitly for now
                            throw URLError(.fileDoesNotExist)
                        } else {
                            // No AR model available for this spot
                            throw URLError(.badURL)
                        }
                        print("🌐 Downloading USDZ from: \(sourceURL.absoluteString)")
                        if sourceURL.isFileURL {
                            data = try Data(contentsOf: sourceURL)
                        } else {
                            let (downloaded, response) = try await URLSession.shared.data(from: sourceURL)
                            if let http = response as? HTTPURLResponse { print("HTTP: \(http.statusCode), bytes: \(downloaded.count)") }
                            data = downloaded
                        }
                    }
                    if Task.isCancelled { return }

                    // Write to caches for stable local loading
                    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
                    let fileURL = caches.appendingPathComponent("ar_usdz_\(self.spot.id).usdz")
                    try? FileManager.default.removeItem(at: fileURL)
                    try data.write(to: fileURL)

                    // Load USDZ ModelEntity from local caches file
                    let loadedEntity = try await ModelEntity.load(contentsOf: fileURL)
                    loadedEntity.generateCollisionShapes(recursive: true)
                    if Task.isCancelled { return }

                    // Update UI only if this anchor is still the latest
                    await MainActor.run {
                        guard self.lastPlacedAnchor == anchor else { return }
                        ghostEntity.removeFromParent()
                        anchor.addChild(loadedEntity)
                    }
                } catch {
                    if Task.isCancelled { return }
                    print("❌ Model loading failed: \(error)")
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
            guard let arView = arView else { return }
            
            let captureResult = checkCaptureCondition(arView: arView)

            arView.snapshot(saveToHDR: false) { [weak self] image in
                DispatchQueue.main.async {
                    guard let self = self, let capturedImage = image else { return }
                    
                    let newAsset = PhotoAsset(image: capturedImage, result: captureResult)
                    self.photoCollection.assets.append(newAsset)
                }
            }
        }
        
        private func checkCaptureCondition(arView: ARView) -> Result<Void, CaptureFailureReason> {
            guard let model = lastPlacedAnchor else {
                return .failure(.noModelPlaced)
            }
            
            guard let projectedPoint = arView.project(model.position(relativeTo: nil)) else {
                return .failure(.modelNotInView)
            }
            
            if arView.bounds.contains(projectedPoint) {
                return .success(())           } else {
                return .failure(.modelNotInView)
            }
        }

        func updateScale(_ newScale: Float) {
            lastPlacedAnchor?.setScale(SIMD3<Float>(repeating: newScale), relativeTo: nil)
        }
    }
}

