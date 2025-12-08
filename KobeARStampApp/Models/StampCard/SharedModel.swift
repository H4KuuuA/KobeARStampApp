//
//  SharedModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/27.
//

import SwiftUI

@Observable
class SharedModel {
    var sampleimages: [SampleImage] = file
    
    /// URLから画像を非同期で読み込む
    func loadImage(for sampleImage: Binding<SampleImage>) async {
        // URLがない場合は何もしない
        guard let url = sampleImage.wrappedValue.fileURL else { return }

        guard let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else { return }

        await MainActor.run {
            sampleImage.wrappedValue.image = uiImage
        }
    }
}
