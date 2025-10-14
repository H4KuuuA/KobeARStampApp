//
//  Notifications.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import Foundation

extension Notification.Name {
    
    /// スナップショットの撮影をARViewにリクエストするための通知名
    static let takeSnapshot = Notification.Name("takeSnapshot")
    
    /// スナップショットの撮影が完了したことをUIに知らせるための通知名
    static let snapshotTaken = Notification.Name("snapshotTaken")
    
    /// カスタムピンがタップされたことを通知
    static let customPinTapped = Notification.Name("customPinTapped")
    
    /// カスタムピンの選択が解除されたことを通知
    static let customPinDeselected = Notification.Name("customPinDeselected")
    
    /// ローカルを通知をタップしタップしたことを通知
    static let openPinDetail = Notification.Name("openPinDetail")
}
