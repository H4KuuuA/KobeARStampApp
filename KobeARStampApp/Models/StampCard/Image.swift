//
//  Image.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

/// Video -> Image
struct SampleImage: Identifiable, Hashable {
    var id: UUID = .init()
    var image: UIImage
    // 将来変更
    // var fileURL: URL
    var tumbnail: UIImage?
    }

/// Sample Image
let file = [
    SampleImage(image: UIImage(named: "hatkobe_1")!),
    SampleImage(image: UIImage(named: "hatkobe_2")!),
    SampleImage(image: UIImage(named: "hatkobe_3")!),
    SampleImage(image: UIImage(named: "hatkobe_4")!),
    SampleImage(image: UIImage(named: "hatkobe_5")!),
    SampleImage(image: UIImage(named: "hatkobe_6")!),
]


