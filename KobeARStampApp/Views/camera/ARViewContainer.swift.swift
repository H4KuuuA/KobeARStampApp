
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

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal]
        arView.session.run(config)

        let box = MeshResource.generateBox(size: 0.1 * scale)
        let material = SimpleMaterial(color: .blue, isMetallic: false)
        let entity = ModelEntity(mesh: box, materials: [material])

        let anchor = AnchorEntity(plane: .horizontal)
        anchor.addChild(entity)
        arView.scene.anchors.append(anchor)

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // スケール変更時の反映は、必要なら実装
    }
}

    
    
    





