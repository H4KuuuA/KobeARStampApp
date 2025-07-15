
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

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        
        // CoordinatorにARViewのインスタンスを渡します
        context.coordinator.arView = arView
        
        // ARの基本設定
        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal] // 水平な平面を検出
        arView.session.run(config)
        
        // タップジェスチャーを追加し、Coordinatorのメソッドを呼び出すように設定
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap))
        arView.addGestureRecognizer(tapGesture)
        
        // スナップショット撮影の通知を監視する設定
        context.coordinator.setupSnapshotObserver()

        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        // SwiftUI側でスケールが変更されたら、Coordinator経由でオブジェクトのサイズを更新
        context.coordinator.updateObjectScale(scale: scale)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // ARKitのデリゲートや、ARViewのイベント処理を担当します。
    class Coordinator: NSObject {
        var parent: ARViewContainer
        weak var arView: ARView?
        var objectAnchor: AnchorEntity? // 配置したオブジェクトを保持するアンカー

        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        /// ユーザーが画面をタップした時の処理
        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let location = sender.location(in: arView)
            
            // タップした位置に平面があるか判定
            let results = arView.raycast(from: location, allowing: .estimatedPlane, alignment: .horizontal)
            
            if let firstResult = results.first {
                // すでにオブジェクトが配置されている場合は、その位置を移動
                if let anchor = objectAnchor {
                    anchor.transform.matrix = firstResult.worldTransform
                } else {
                    // オブジェクトがまだない場合は、新規に作成して配置
                    let newAnchor = AnchorEntity(world: firstResult.worldTransform)
                    
                    // TODO: キャラクターモデルの読み込み
                    // 例: let modelEntity = try! ModelEntity.load(named: "character.usdz")
                    let modelEntity = ModelEntity(mesh: MeshResource.generateBox(size: 0.1, cornerRadius: 0.02),
                                                  materials: [SimpleMaterial(color: .systemBlue, isMetallic: false)])
                    
                    newAnchor.addChild(modelEntity)
                    arView.scene.addAnchor(newAnchor)
                    self.objectAnchor = newAnchor
                }
                // スケールを適用
                updateObjectScale(scale: parent.scale)
            }
        }
        
        /// オブジェクトのスケールを更新
        func updateObjectScale(scale: Float) {
            objectAnchor?.setScale(SIMD3<Float>(repeating: scale), relativeTo: nil)
        }
        
        /// スナップショット撮影の通知を監視する設定
        func setupSnapshotObserver() {
            NotificationCenter.default.addObserver(self, selector: #selector(takeSnapshot), name: .takeSnapshot, object: nil)
        }
        
        /// スナップショットを撮影し、結果を通知する
        @objc func takeSnapshot() {
            arView?.snapshot(saveToHDR: false) { image in
                // 撮影した画像を付けて、UI側に通知
                NotificationCenter.default.post(name: .snapshotTaken, object: image)
            }
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
}


    
    
    





