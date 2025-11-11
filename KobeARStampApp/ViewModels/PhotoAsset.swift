//
//  PhotoAsset.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import SwiftUI

// 撮影した写真を一意に識別するためのデータ構造
import SwiftUI

/// A data structure to uniquely identify a captured photo, including the capture result.
struct PhotoAsset: Identifiable {
    let id = UUID()
    let image: UIImage
    /// The result of the stamp acquisition check.
    let result: Result<Void, CaptureFailureReason>
    
    /// A convenience property to check if the capture was successful.
    var didSucceed: Bool {
        if case .success = result {
            return true
        }
        return false
    }
}

/// An enum representing the reason for a failed stamp capture.
enum CaptureFailureReason: String, LocalizedError {
    case noModelPlaced = "モデルがまだ配置されていません。"
    case modelNotInView = "モデルが画面内にありません。"
    
    var errorDescription: String? {
        return self.rawValue
    }
}
