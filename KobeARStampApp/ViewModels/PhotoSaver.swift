//
//  PhotoSaver.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/11/10.
//

import SwiftUI
import Photos // Photosフレームワークをインポート

/// UIImageをフォトライブラリに保存するためのヘルパークラス
class PhotoSaver: NSObject, ObservableObject {
    
    /// 保存結果をViewに伝えるためのPublishedプロパティ
    @Published var saveResult: Result<Void, Error>?
    
    /// 画像の保存を実行する
    /// - Parameter image: 保存したいUIImage
    func saveImage(_ image: UIImage) {
        // 保存処理が完了するまで自身を強参照で保持する
        // (コールバックが呼ばれる前にインスタンスが破棄されるのを防ぐため)
        var strongSelf: PhotoSaver? = self
        
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        // 実際にはコールバック内でstrongSelfをnilにするが、
        // このクラスは@StateObjectで使われる想定なので、簡略化しても動作する
        _ = strongSelf // 警告防止
    }
    
    /// UIImageWriteToSavedPhotosAlbumからのコールバック
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        // メインスレッドで結果をViewに通知する
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
