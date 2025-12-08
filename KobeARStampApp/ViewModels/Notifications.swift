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
    
    /// スポットがタップされたことを通知
    static let spotTapped = Notification.Name("spotTapped")
    
    /// スポットに接近したことを通知（位置情報ベース）
    static let spotProximityEntered = Notification.Name("spotProximityEntered")
    
    /// スポットの選択が解除されたことを通知
    static let spotDeselected = Notification.Name("spotDeselected")
    
    /// ローカル通知をタップしたことを通知
    static let openPinDetail = Notification.Name("openPinDetail")
}
