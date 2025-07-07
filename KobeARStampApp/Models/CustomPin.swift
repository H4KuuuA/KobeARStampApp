//
//  CustomPin.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

import Foundation
import CoreLocation

/// カスタムピンの構造体
struct CustomPin: Identifiable {
    //　一意の識別子
    let id: UUID
    // ピンのタイトル
    var title: String
    // タイトルの補足説明
    var subtitle: String?
    // 緯度・経度の座標
    var coordinate: CLLocationCoordinate2D
    // ピンの色
    var pinColorName: String?
    // カスタムピンの画像名
    var imageURL: URL?
    // 詳細説明や備考
    var description: String?
    // カテゴリ分け
    var category: String?
    // 作成日時
    var createdAt: Date
    // 更新日時
    var updatedAt: Date?
}

