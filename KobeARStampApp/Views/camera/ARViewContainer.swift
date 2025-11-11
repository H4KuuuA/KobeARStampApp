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
    
    @Binding var scale: Float
    let snapshotTrigger: PassthroughSubject<Void, Never>
    @ObservedObject var photoCollection: PhotoCollection

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        context.coordinator.arView = arView
        
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = .horizontal
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
        Coordinator(spot: spot, snapshotTrigger: snapshotTrigger, photoCollection: photoCollection)
    }

    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        weak var arView: ARView?
        var cancellables = Set<AnyCancellable>()
        private var lastPlacedAnchor: AnchorEntity?
        
        let spot: Spot
        
        let snapshotTrigger: PassthroughSubject<Void, Never>
        let photoCollection: PhotoCollection

        init(spot: Spot, snapshotTrigger: PassthroughSubject<Void, Never>, photoCollection: PhotoCollection) {
                    self.spot = spot
                    self.snapshotTrigger = snapshotTrigger
                    self.photoCollection = photoCollection
                }
        
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView,
                  let query = arView.makeRaycastQuery(from: recognizer.location(in: arView), allowing: .estimatedPlane, alignment: .horizontal),
                  let firstResult = arView.session.raycast(query).first else {
                return
            }
            
            let anchor = AnchorEntity(world: firstResult.worldTransform)
            
            // NOTE: This is a placeholder model. Replace with your actual model loading logic.
            let box = MeshResource.generateBox(size: 0.1)
            let material = SimpleMaterial(color: .systemPink, isMetallic: true)
            let modelEntity = ModelEntity(mesh: box, materials: [material])
            
            modelEntity.generateCollisionShapes(recursive: true)
            anchor.addChild(modelEntity)
            arView.scene.addAnchor(anchor)
            lastPlacedAnchor = anchor
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
                return .success(())
            } else {
                return .failure(.modelNotInView)
            }
        }

        func updateScale(_ newScale: Float) {
            lastPlacedAnchor?.setScale(SIMD3<Float>(repeating: newScale), relativeTo: nil)
        }
    }
}
