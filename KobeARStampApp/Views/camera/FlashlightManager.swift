//
//  FlashlightManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/09/08.
//

import AVFoundation

// デバイスのトーチ（フラッシュライト）を制御するための管理クラス
class FlashlightManager {
    
    /// トーチのON/OFFを切り替える静的メソッド
    /// - Parameter on: trueでON、falseでOFF
    static func toggleFlash(on: Bool) {
        // ビデオキャプチャ用のデフォルトデバイスを取得
        guard let device = AVCaptureDevice.default(for: .video) else {
            print("Error: Could not get the default video device.")
            return
        }

        // デバイスがトーチ（フラッシュ）を持っているか確認
        if device.hasTorch {
            do {
                // デバイスの設定を変更するためにロック
                try device.lockForConfiguration()

                // トーチのモードを設定
                device.torchMode = on ? .on : .off
                
                // （オプション）トーチの明るさを設定することも可能
                // if on {
                //     try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
                // }

                // デバイスのロックを解除
                device.unlockForConfiguration()
            } catch {
                print("Error: Could not set the torch mode: \(error)")
            }
        } else {
            print("Error: This device does not have a torch.")
        }
    }
}
