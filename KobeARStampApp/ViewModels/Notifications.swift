//
//  Notifications.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import Foundation

// アプリケーション全体で利用する通知名を定義します。
// これにより、通知の名前を文字列で直接書く必要がなくなり、安全になります。
extension Notification.Name {
    
    /// スナップショットの撮影をARViewにリクエストするための通知名
    static let takeSnapshot = Notification.Name("takeSnapshot")
    
    /// スナップショットの撮影が完了したことをUIに知らせるための通知名
    static let snapshotTaken = Notification.Name("snapshotTaken")
}
