//
//  Image.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

/// Video -> Image
struct Image: Identifiable, Hashable {
    var id: UUID = .init()
    var image: UIImage
    // 将来変更
    // var fileURL: URL
    var tumbnail: UIImage?
    }

/// Sample Image
let file = [
    Image(image: UIImage(named: "hatkobe_1")!),
    Image(image: UIImage(named: "hatkobe_2")!),
    Image(image: UIImage(named: "hatkobe_3")!),
    Image(image: UIImage(named: "hatkobe_4")!),
    Image(image: UIImage(named: "hatkobe_5")!),
    Image(image: UIImage(named: "hatkobe_6")!),
]


