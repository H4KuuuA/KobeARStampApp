
//
//  ARSnapshotManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import UIKit
import RealityKit
import ARKit
import CoreImage
import CoreImage.CIFilterBuiltins

class ARSnapshotManager {

    /// UIView階層からARViewを再帰的に探索する
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

    /// ARViewからスナップショットを撮影
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

    /// 画像をアプリ内に保存
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

    /// フィルターを適用
    static func applyFilter(to image: UIImage, filterName: String) -> UIImage {
        guard let ciImage = CIImage(image: image),
              let filter = CIFilter(name: filterName) else {
            return image
        }

        filter.setValue(ciImage, forKey: kCIInputImageKey)
        let context = CIContext()
        if let outputImage = filter.outputImage,
           let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }

        return image
    }

    /// 利用可能なフィルター一覧
    static func availableFilters() -> [String] {
        return [
            "CIPhotoEffectMono",
            "CIPhotoEffectChrome",
            "CIPhotoEffectInstant",
            "CIPhotoEffectNoir",
            "CISepiaTone",
            "CIColorInvert"
        ]
    }
}
