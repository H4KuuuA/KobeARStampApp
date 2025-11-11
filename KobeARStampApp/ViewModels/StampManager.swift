//
//  StampManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import SwiftUI

class StampManager: ObservableObject {
    /// The source of truth for all available spots in the rally.
    
    let allSpots: [Spot] = [
        Spot(id: "kobe-port-tower", name: "神戸ポートタワー", placeholderImageName: "spot_placeholder_1", modelName: "port_tower.usdz"),
        Spot(id: "meriken-park", name: "メリケンパーク", placeholderImageName: "spot_placeholder_2", modelName: "meriken_park.usdz"),
        Spot(id: "nankinmachi", name: "南京町", placeholderImageName: "spot_placeholder_3", modelName: "nankinmachi.usdz"),
        Spot(id: "ijinkan", name: "異人館", placeholderImageName: "spot_placeholder_4", modelName: "ijinkan.usdz"),
        // ... more spots
    ]
    
    
    @Published var acquiredStamps: [String: AcquiredStamp] = [:]
    
    // (The rest of the file remains the same)
    // ...
    // ...
    // ...
    
    var acquiredStampCount: Int { acquiredStamps.count }
    var totalSpotCount: Int { allSpots.count }
    var progress: Float {
        guard totalSpotCount > 0 else { return 0 }
        return Float(acquiredStampCount) / Float(totalSpotCount)
    }
    var progressText: String { "\(acquiredStampCount) / \(totalSpotCount)" }
    
    private let stampsDirectoryURL: URL
    private let stampsJSONURL: URL
    
    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        stampsDirectoryURL = documentsURL.appendingPathComponent("StampImages")
        stampsJSONURL = documentsURL.appendingPathComponent("stamps.json")
        try? FileManager.default.createDirectory(at: stampsDirectoryURL, withIntermediateDirectories: true, attributes: nil)
        loadStamps()
    }
    
    func addStamp(image: UIImage, for spot: Spot) {
        guard acquiredStamps[spot.id] == nil else { return }
        let fileName = spot.id + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        do {
            try data.write(to: fileURL)
            let newStamp = AcquiredStamp(id: UUID(), spotID: spot.id, imageFileName: fileName, acquiredDate: Date())
            acquiredStamps[spot.id] = newStamp
            saveStamps()
        } catch {
            print("Failed to save image: \(error.localizedDescription)")
        }
    }
    
    private func saveStamps() {
        do {
            let data = try JSONEncoder().encode(acquiredStamps)
            try data.write(to: stampsJSONURL)
        } catch {
            print("Failed to save stamp list: \(error.localizedDescription)")
        }
    }
    
    private func loadStamps() {
        guard let data = try? Data(contentsOf: stampsJSONURL) else { return }
        do {
            acquiredStamps = try JSONDecoder().decode([String: AcquiredStamp].self, from: data)
        } catch {
            print("Failed to load stamp list: \(error.localizedDescription)")
        }
    }
    
    func getImage(for stamp: AcquiredStamp) -> UIImage? {
        let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
}
