//
//  PhotoAsset.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/07/08.
//

import SwiftUI

// 撮影した写真を一意に識別するためのデータ構造
struct PhotoAsset: Identifiable {
    let id = UUID()
    let image: UIImage
}
