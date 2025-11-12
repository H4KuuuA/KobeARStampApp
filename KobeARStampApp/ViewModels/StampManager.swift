//
//  StampManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import SwiftUI
import CoreLocation

class StampManager: ObservableObject {
    
    // MARK: - All Spots（mockPinsから生成）
    
    let allSpots: [Spot] = [
        // ========== 王子動物園エリア（3箇所） ==========
        Spot(
            id: "ojizoo-panda",
            name: "パンダエリア",
            placeholderImageName: "hatkobe_1",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.709591901580474, longitude: 135.21519562134145),
            subtitle: "王子動物園のパンダ",
            category: "動物園"
        ),
        Spot(
            id: "ojizoo-elephant",
            name: "ゾウ広場",
            placeholderImageName: "hatkobe_2",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.71040, longitude: 135.21580),
            subtitle: "王子動物園のゾウ",
            category: "動物園"
        ),
        Spot(
            id: "ojizoo-flamingo",
            name: "フラミンゴ池",
            placeholderImageName: "hatkobe_3",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.70880, longitude: 135.21450),
            subtitle: "王子動物園のフラミンゴ",
            category: "動物園"
        ),
        
        // ========== 兵庫県立美術館エリア（3箇所） ==========
        Spot(
            id: "museum-entrance",
            name: "美術館入口",
            placeholderImageName: "hatkobe_4",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.700080471831484, longitude: 135.21794931523175),
            subtitle: "兵庫県立美術館",
            category: "美術館"
        ),
        Spot(
            id: "museum-deck",
            name: "海のデッキ",
            placeholderImageName: "hatkobe_5",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69950, longitude: 135.21850),
            subtitle: "美術館の海側デッキ",
            category: "美術館"
        ),
        Spot(
            id: "museum-garden",
            name: "彫刻の庭",
            placeholderImageName: "hatkobe_6",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.70080, longitude: 135.21700),
            subtitle: "美術館の彫刻エリア",
            category: "美術館"
        ),
        
        // ========== HAT神戸エリア（4箇所） ==========
        Spot(
            id: "hat-walk",
            name: "海辺の散歩道",
            placeholderImageName: "hatkobe_1",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69782178897619, longitude: 135.21539125345234),
            subtitle: "HAT神戸の海沿い",
            category: "HAT神戸"
        ),
        Spot(
            id: "hat-art",
            name: "芸術広場",
            placeholderImageName: "hatkobe_2",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69850, longitude: 135.21600),
            subtitle: "HAT神戸の芸術広場",
            category: "HAT神戸"
        ),
        Spot(
            id: "hat-music",
            name: "音楽の丘",
            placeholderImageName: "hatkobe_3",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69700, longitude: 135.21480),
            subtitle: "HAT神戸の音楽施設",
            category: "HAT神戸"
        ),
        Spot(
            id: "hat-monument",
            name: "記念碑",
            placeholderImageName: "hatkobe_4",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69650, longitude: 135.21420),
            subtitle: "HAT神戸の記念碑",
            category: "HAT神戸"
        ),
    ]
    
    // MARK: - Published Properties
    
    @Published var acquiredStamps: [String: AcquiredStamp] = [:]
    
    // MARK: - Computed Properties
    
    var acquiredStampCount: Int {
        acquiredStamps.count
    }
    
    var totalSpotCount: Int {
        allSpots.count
    }
    
    var progress: Float {
        guard totalSpotCount > 0 else { return 0 }
        return Float(acquiredStampCount) / Float(totalSpotCount)
    }
    
    var progressText: String {
        "\(acquiredStampCount) / \(totalSpotCount)"
    }
    
    // MARK: - File Management
    
    private let stampsDirectoryURL: URL
    private let stampsJSONURL: URL
    
    // MARK: - Initialization
    
    init() {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        stampsDirectoryURL = documentsURL.appendingPathComponent("StampImages")
        stampsJSONURL = documentsURL.appendingPathComponent("stamps.json")
        
        // ディレクトリを作成
        try? FileManager.default.createDirectory(
            at: stampsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        loadStamps()
    }
    
    // MARK: - Stamp Management
    
    /// スタンプを追加
    func addStamp(image: UIImage, for spot: Spot) {
        guard acquiredStamps[spot.id] == nil else {
            print("⚠️ スタンプは既に取得済み: \(spot.name)")
            return
        }
        
        let fileName = spot.id + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 画像のJPEG変換に失敗")
            return
        }
        
        do {
            try data.write(to: fileURL)
            let newStamp = AcquiredStamp(
                id: UUID(),
                spotID: spot.id,
                imageFileName: fileName,
                acquiredDate: Date()
            )
            acquiredStamps[spot.id] = newStamp
            saveStamps()
            print("✅ スタンプを保存: \(spot.name)")
        } catch {
            print("❌ 画像保存失敗: \(error.localizedDescription)")
        }
    }
    
    /// スタンプが取得済みかチェック
    func isStampAcquired(spotID: String) -> Bool {
        return acquiredStamps[spotID] != nil
    }
    
    /// スポットIDからSpotを取得
    func getSpot(by id: String) -> Spot? {
        return allSpots.first { $0.id == id }
    }
    
    // MARK: - Image Retrieval
    
    /// AcquiredStampから画像を取得
    func getImage(for stamp: AcquiredStamp) -> UIImage? {
        let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return UIImage(data: data)
    }
    
    /// Spotから画像を取得（取得済みの場合のみ）
    func getImage(for spot: Spot) -> UIImage? {
        guard let stamp = acquiredStamps[spot.id] else {
            return nil
        }
        return getImage(for: stamp)
    }
    
    // MARK: - Persistence
    
    /// スタンプリストをJSONに保存
    private func saveStamps() {
        do {
            let data = try JSONEncoder().encode(acquiredStamps)
            try data.write(to: stampsJSONURL)
            print("✅ スタンプリストを保存")
        } catch {
            print("❌ スタンプリスト保存失敗: \(error.localizedDescription)")
        }
    }
    
    /// スタンプリストをJSONから読み込み
    private func loadStamps() {
        guard let data = try? Data(contentsOf: stampsJSONURL) else {
            print("ℹ️ スタンプリストが見つかりません（初回起動）")
            return
        }
        
        do {
            acquiredStamps = try JSONDecoder().decode([String: AcquiredStamp].self, from: data)
            print("✅ スタンプリストを読み込み: \(acquiredStamps.count)個")
        } catch {
            print("❌ スタンプリスト読み込み失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Category Filtering
    
    /// カテゴリ別にスポットをフィルタリング
    func getSpots(by category: String) -> [Spot] {
        return allSpots.filter { $0.category == category }
    }
    
    /// 全カテゴリを取得
    var allCategories: [String] {
        let categories = allSpots.compactMap { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // MARK: - Debug
    
    #if DEBUG
    /// 全スタンプをリセット（デバッグ用）
    func resetAllStamps() {
        // 画像ファイルを削除
        for stamp in acquiredStamps.values {
            let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        
        // メモリとJSONをクリア
        acquiredStamps.removeAll()
        saveStamps()
        print("🔄 全スタンプをリセットしました")
    }
    
    /// 特定のスタンプをリセット
    func resetStamp(spotID: String) {
        guard let stamp = acquiredStamps[spotID] else { return }
        
        let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
        try? FileManager.default.removeItem(at: fileURL)
        
        acquiredStamps.removeValue(forKey: spotID)
        saveStamps()
        print("🔄 スタンプをリセット: \(spotID)")
    }
    #endif
}
