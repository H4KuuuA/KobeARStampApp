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
        Coordinator(snapshotTrigger: snapshotTrigger, photoCollection: photoCollection)
    }

    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        weak var arView: ARView?
        var cancellables = Set<AnyCancellable>()
        private var lastPlacedAnchor: AnchorEntity?
        
        let snapshotTrigger: PassthroughSubject<Void, Never>
        let photoCollection: PhotoCollection

        init(snapshotTrigger: PassthroughSubject<Void, Never>, photoCollection: PhotoCollection) {
            self.snapshotTrigger = snapshotTrigger
            self.photoCollection = photoCollection
        }

        /// タップでモデルを配置するメソッド
        @objc func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let arView = arView, lastPlacedAnchor == nil else { return }
            
            let location = recognizer.location(in: arView)
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)

            if let firstResult = results.first {
                let anchor = AnchorEntity(world: firstResult.worldTransform)
                
                let modelName = "Dragon_2.5_For_Animations.usdz"
                ModelEntity.loadModelAsync(named: modelName)
                    .receive(on: RunLoop.main)
                    .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] modelEntity in
                        
                        if let animation = modelEntity.availableAnimations.first {
                            modelEntity.playAnimation(animation.repeat())
                        }
                        
                        modelEntity.generateCollisionShapes(recursive: true)
                        anchor.addChild(modelEntity)
                        arView.scene.addAnchor(anchor)
                        self?.lastPlacedAnchor = anchor
                    })
                    .store(in: &cancellables)
            }
        }
        
        /// シャッターボタンの合図を監視する
        func subscribeToActionStream() {
            snapshotTrigger
                .sink { [weak self] in
                    self?.takeSnapshot()
                }
                .store(in: &cancellables)
        }

        /// スナップショットを撮影する
        func takeSnapshot() {
                    arView?.snapshot(saveToHDR: false) { [weak self] image in
                        
                        
                        // snapshot完了後の処理を、ブロックごと全てメインスレッドに送る
                        DispatchQueue.main.async {
                            // メインスレッド内で、安全にselfとimageを展開する
                            guard let self = self, let capturedImage = image else { return }
                            
                            let newAsset = PhotoAsset(image: capturedImage)
                            self.photoCollection.assets.append(newAsset)
                        }
                        
                    }
                }

        func updateScale(_ newScale: Float) {
            // スケール変更ロジックは今後こちらに実装
            lastPlacedAnchor?.setScale(SIMD3<Float>(repeating: newScale), relativeTo: nil)
        }
    }
}
