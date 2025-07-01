
//
//  ARSnapshotManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import UIKit
import RealityKit
import ARKit
/// ARカメラに関するスナップショット処理やファイル保存処理を管理するクラス
class ARSnapshotManager {
    /// UIView階層からARViewを再帰的に探索する
    /// - Parameter view: 探索を始めるUIView
    /// - Returns: 最初に見つかったARView（存在しない場合はnil）
    static func findARView(from view: UIView) -> ARView? {
        if let arView = view as? ARView {
            return arView
        }
        for subview in view.subviews {
            if let found = findARView(from: subview) {
                return found
            }
        }
        return nil
    }
    /// ARViewから現在の表示をキャプチャしてUIImageとして返す
    /// - Parameters:
    ///   - rootView: ARViewが含まれるルートビュー（通常はWindowのrootView）
    ///   - completion: キャプチャ結果（UIImage）を非同期で返すクロージャ
    static func takeSnapshot(from rootView: UIView, completion: @escaping (UIImage?) -> Void) {
        guard let arView = findARView(from: rootView) else {
            print("ARViewが見つかりません")
            completion(nil)
            return
        }

        arView.snapshot(saveToHDR: false) { image in
            completion(image)
        }
    }
    /// UIImageをアプリのDocumentディレクトリ内にJPEG形式で保存する
    /// - Parameter image: 保存対象のUIImage
    /// - Returns: 保存に成功した場合はファイルのURL、失敗した場合はnil
    static func saveImageToAppDirectory(image: UIImage) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.9) else { return nil }
        let filename = UUID().uuidString + ".jpg"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        do {
            try data.write(to: url)
            return url
        } catch {
            print("保存失敗: \(error)")
            return nil
        }
    }
}


