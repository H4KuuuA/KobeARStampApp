//
//  PhotoSaver.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/11/10.
//

import SwiftUI
import Photos

/// UIImageをフォトライブラリとアプリディレクトリに保存するためのヘルパークラス
class PhotoSaver: NSObject, ObservableObject {
    
    /// 保存結果をViewに伝えるためのPublishedプロパティ
    @Published var saveResult: Result<Void, Error>?
    
    /// 画像をフォトライブラリとアプリディレクトリの両方に保存する
    /// - Parameters:
    ///   - image: 保存したいUIImage
    ///   - spot: 関連するSpot（スタンプの保存先を決定するため）
    @MainActor func saveImage(_ image: UIImage, for spot: Spot) {
        Task {
            // 位置情報を取得（オプション）
            let latitude = LocationManager.shared.latitude
            let longitude = LocationManager.shared.longitude
            let currentEvent = StampManager.shared.currentEvent
            
            // Supabaseベースで保存
            await StampManager.shared.addStamp(
                image: image,
                for: spot,
                event: currentEvent,
                latitude: latitude,
                longitude: longitude
            )
            
            // フォトライブラリにも保存
            saveToPhotoLibrary(image)
        }
    }
    
    /// フォトライブラリのみに保存（既存の機能を保持）
    /// - Parameter image: 保存したいUIImage
    func saveImage(_ image: UIImage) {
        saveToPhotoLibrary(image)
    }
    
    /// フォトライブラリに画像を保存する内部メソッド
    private func saveToPhotoLibrary(_ image: UIImage) {
        let strongSelf: PhotoSaver? = self
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        _ = strongSelf // 警告防止
    }
    
    /// UIImageWriteToSavedPhotosAlbumからのコールバック
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        DispatchQueue.main.async {
            if let error = error {
                print("写真の保存に失敗: \(error.localizedDescription)")
                self.saveResult = .failure(error)
            } else {
                print("写真の保存に成功")
                self.saveResult = .success(())
            }
        }
    }
}
