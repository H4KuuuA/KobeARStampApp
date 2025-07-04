
//
//  ARViewContainer.swift.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import SwiftUI
import RealityKit
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @Binding var scale: Float

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        // AR構成設定
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        // 仮のモデルを追加
        let box = MeshResource.generateBox(size: 0.1 * scale)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let entity = ModelEntity(mesh: box, materials: [material])

        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(entity)
        arView.scene.anchors.append(anchor)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // スケール更新処理（必要に応じて）
    }
}

    
    
    





