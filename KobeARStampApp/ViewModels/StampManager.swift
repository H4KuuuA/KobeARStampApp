//
//  StampManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import SwiftUI
import CoreLocation

class StampManager: ObservableObject {
    
    // MARK: - Properties
    
    /// スポットのリスト(将来的にはDBから取得)
    @Published var allSpots: [Spot] = []
    
    /// 取得済みスタンプ(ローカル保存)
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
        
        try? FileManager.default.createDirectory(
            at: stampsDirectoryURL,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        loadSpots()  // ← 先にスポットを読み込む
        loadStamps() // ← その後にスタンプを読み込む
    }
    
    // MARK: - Spot Management
    
    /// スポットを読み込む(将来的にはDBから)
    private func loadSpots() {
        // 現在はハードコード、将来的にはDB連携
        allSpots = Self.defaultSpots
    }
    
    /// DBからスポットを取得(将来の実装)
    func fetchSpotsFromDB() async throws {
        // TODO: Firebase/Supabaseから取得
        // let spots = try await spotRepository.fetchSpots()
        // await MainActor.run {
        //     self.allSpots = spots
        // }
    }
    
    /// スポットIDからSpotを取得
    func getSpot(by id: String) -> Spot? {
        return allSpots.first { $0.id == id }
    }
    
    // MARK: - Stamp Management
    
    /// スタンプを追加(トランザクション的)
    func addStamp(image: UIImage, for spot: Spot) {
        // 1. 既に取得済みかチェック
        guard acquiredStamps[spot.id] == nil else {
            print("⚠️ スタンプは既に取得済み: \(spot.name)")
            return
        }
        
        // 2. Spotが有効か検証(DBから削除されていないか)
        guard getSpot(by: spot.id) != nil else {
            print("❌ 無効なスポット: \(spot.id)")
            return
        }
        
        // 3. 画像を保存
        let fileName = spot.id + ".jpeg"
        let fileURL = stampsDirectoryURL.appendingPathComponent(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ 画像のJPEG変換に失敗")
            return
        }
        
        do {
            try data.write(to: fileURL)
            
            // 4. メタデータを保存
            let newStamp = AcquiredStamp(
                id: UUID(),
                spotID: spot.id,
                imageFileName: fileName,
                acquiredDate: Date()
            )
            acquiredStamps[spot.id] = newStamp
            saveStamps()
            
            print("✅ スタンプを保存: \(spot.name)")
            
            // 5. オプション: サーバーに同期
            // Task {
            //     try? await syncStampToServer(stamp: newStamp)
            // }
            
        } catch {
            print("❌ 画像保存失敗: \(error.localizedDescription)")
        }
    }
    
    /// スタンプが取得済みかチェック
    func isStampAcquired(spotID: String) -> Bool {
        return acquiredStamps[spotID] != nil
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
    
    /// Spotから画像を取得(取得済みの場合のみ)
    func getImage(for spot: Spot) -> UIImage? {
        guard let stamp = acquiredStamps[spot.id] else {
            return nil
        }
        return getImage(for: stamp)
    }
    
    // MARK: - Persistence (Local)
    
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
            print("ℹ️ スタンプリストが見つかりません(初回起動)")
            return
        }
        
        do {
            acquiredStamps = try JSONDecoder().decode([String: AcquiredStamp].self, from: data)
            print("✅ スタンプリストを読み込み: \(acquiredStamps.count)個")
            
            // DBから削除されたSpotのスタンプをクリーンアップ
            cleanupOrphanedStamps()
            
        } catch {
            print("❌ スタンプリスト読み込み失敗: \(error.localizedDescription)")
        }
    }
    
    /// DBから削除されたスポットのスタンプを削除
    private func cleanupOrphanedStamps() {
        let validSpotIDs = Set(allSpots.map { $0.id })
        let orphanedStampIDs = acquiredStamps.keys.filter { !validSpotIDs.contains($0) }
        
        for stampID in orphanedStampIDs {
            if let stamp = acquiredStamps[stampID] {
                let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
                try? FileManager.default.removeItem(at: fileURL)
                acquiredStamps.removeValue(forKey: stampID)
                print("🧹 孤立したスタンプを削除: \(stampID)")
            }
        }
        
        if !orphanedStampIDs.isEmpty {
            saveStamps()
        }
    }
    
    // MARK: - Sync (Future Implementation)
    
    /// サーバーにスタンプ取得履歴を同期(将来の実装)
    private func syncStampToServer(stamp: AcquiredStamp) async throws {
        // TODO: Firebase/Supabaseに送信
        // await apiClient.uploadStampAcquisition(
        //     userID: currentUserID,
        //     spotID: stamp.spotID,
        //     acquiredDate: stamp.acquiredDate
        // )
    }
    
    // MARK: - Category Filtering
    
    func getSpots(by category: String) -> [Spot] {
        return allSpots.filter { $0.category == category }
    }
    
    var allCategories: [String] {
        let categories = allSpots.compactMap { $0.category }
        return Array(Set(categories)).sorted()
    }
    
    // MARK: - Debug
    
    #if DEBUG
    func resetAllStamps() {
        for stamp in acquiredStamps.values {
            let fileURL = stampsDirectoryURL.appendingPathComponent(stamp.imageFileName)
            try? FileManager.default.removeItem(at: fileURL)
        }
        acquiredStamps.removeAll()
        saveStamps()
        print("🔄 全スタンプをリセットしました")
    }
    
    /// デバッグ用: プレースホルダー画像を使って特定のスポットのスタンプを取得済みにする
    func debugAcquireStamp(spotID: String) {
        guard let spot = getSpot(by: spotID) else {
            print("❌ スポットが見つかりません: \(spotID)")
            return
        }
        
        // プレースホルダー画像を取得
        guard let placeholderImage = UIImage(named: spot.placeholderImageName) else {
            print("❌ プレースホルダー画像が見つかりません: \(spot.placeholderImageName)")
            return
        }
        
        // スタンプとして保存
        addStamp(image: placeholderImage, for: spot)
        print("✅ デバッグ: \(spot.name) のスタンプを取得しました")
    }
    
    /// デバッグ用: 最初のスポットのスタンプを取得済みにする
    func debugAcquireFirstStamp() {
        guard let firstSpot = allSpots.first else {
            print("❌ スポットが存在しません")
            return
        }
        debugAcquireStamp(spotID: firstSpot.id)
    }
    
    /// デバッグ用: 複数のスポットをまとめて取得済みにする
    func debugAcquireMultipleStamps(spotIDs: [String]) {
        for spotID in spotIDs {
            debugAcquireStamp(spotID: spotID)
        }
    }
    
    /// デバッグ用: ランダムに指定数のスタンプを取得する
    func debugAcquireRandomStamps(count: Int) {
        let availableSpots = allSpots.filter { !isStampAcquired(spotID: $0.id) }
        let spotsToAcquire = availableSpots.shuffled().prefix(count)
        
        for spot in spotsToAcquire {
            debugAcquireStamp(spotID: spot.id)
        }
    }
    #endif
}

// MARK: - Default Spots (mockPinsに対応した10箇所 + 説明文 + マップ表示情報)

extension StampManager {
    static let defaultSpots: [Spot] = [
        Spot(
            id: "nada-north-plaza",
            name: "灘駅北口広場",
            placeholderImageName: "hatkobe_1",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.70622423097614, longitude: 135.21616725739096),
            subtitle: "灘駅北側の待ち合わせ広場",
            category: "公園",
            description: "灘駅の北口にある広場。集合や待ち合わせに便利なスポットです。",
            pinColorName: "#FF0000",
            imageURL: URL(string: "https://example.com/images/nada_north_plaza.png")
        ),
        Spot(
            id: "minume-shrine",
            name: "敏馬神社社殿",
            placeholderImageName: "hatkobe_2",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.70344357985072, longitude: 135.21879732451967),
            subtitle: "海風香る縁切りの社",
            category: "文化",
            description: "敏馬神社は、灘区の海沿いに位置する歴史ある神社です。古くから水神を祀り、漁業や航海の守護とともに、縁切りの神としても知られています。海風に包まれ、灘の人々の信仰と文化を今に伝える神社です。",
            pinColorName: "#0000FF",
            imageURL: URL(string: "https://example.com/images/nada_south_cafe.png")
        ),
        Spot(
            id: "nagisa-park",
            name: "なぎさ公園",
            placeholderImageName: "hatkobe_3",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.6970625279125, longitude: 135.21454865587015),
            subtitle: "海風とアートが彩る公園",
            category: "公園",
            description: "なぎさ公園は灘区の海沿いに広がる都市公園で、芝生広場やウォーキングコース、アートモニュメントが楽しめる憩いの場です。",
            pinColorName: "#00FF00",
            imageURL: URL(string: "https://example.com/images/nada_central_park.png")
        ),
        Spot(
            id: "saigo-river-park",
            name: "西郷河川公園",
            placeholderImageName: "hatkobe_4",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.702412041570284, longitude: 135.22474839795566),
            subtitle: "川のそばでバスケも遊びも",
            category: "公園",
            description: "住宅街にひっそり佇む 西郷川河口公園 は、河口ならではの開放感と桜が楽しめる小さな都市公園。バスケットゴールも３箇所あり、遊びとくつろぎが両立する場所です。",
            pinColorName: "#FFFF00",
            imageURL: URL(string: "https://example.com/images/rokkodo_gallery.png")
        ),
        Spot(
            id: "museum-road",
            name: "ミュージアムロード",
            placeholderImageName: "hatkobe_5",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.701138596503135, longitude: 135.2180575627066),
            subtitle: "文化が連なるアート街道",
            category: "アート",
            description: "兵庫県立美術館から神戸市立王子動物園まで約1.2 kmにわたる散策路。多彩な美術館・動物園・パブリックアートが並び、灘区の『芸術と文化の軸』を体感できます。",
            pinColorName: "#FFA500",
            imageURL: URL(string: "https://example.com/images/oji_park_area.png")
        ),
        Spot(
            id: "hyogo-museum",
            name: "兵庫県立美術館",
            placeholderImageName: "hatkobe_6",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.69938435220899, longitude: 135.21824370509106),
            subtitle: "海辺に佇むモダンアートの殿堂",
            category: "アート",
            description: "世界的建築家 安藤忠雄 設計による建築美と現代アートが融合するギャラリー空間です。家族や大人も楽しめる展覧会や教育プログラムも充実しています。",
            pinColorName: "#00FFFF",
            imageURL: URL(string: "https://example.com/images/coast_walk_view.png")
        ),
        Spot(
            id: "disaster-memorial-center",
            name: "震災記念21世紀研究機構",
            placeholderImageName: "hatkobe_1",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.699200000000, longitude: 135.216300000000),
            subtitle: "震災の記憶を未来へ紡ぐ",
            category: "教育",
            description: "阪神・淡路大震災を契機に、地域の安心・人のケア・共生社会の実現に向けて調査研究を行い、知見を社会に届ける専門機関です。",
            pinColorName: "#800080",
            imageURL: URL(string: "https://example.com/images/hat_art_south.png")
        ),
        Spot(
            id: "oji-zoo",
            name: "王子動物園",
            placeholderImageName: "hatkobe_2",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.70978782499848, longitude: 135.21521542400927),
            subtitle: "六甲山麓に広がる動物公園",
            category: "娯楽",
            description: "約120種700点以上の動物たちが暮らし、コアラやゾウ、フラミンゴなど様々な動物を観察できます。遊園地や旧ハンター住宅などの歴史的建造物も併設され、家族連れにも楽しめるスポットです。",
            pinColorName: "#FF00FF",
            imageURL: URL(string: "https://example.com/images/hat_coast_north.png")
        ),
        Spot(
            id: "yokoo-museum",
            name: "横尾忠則現代美術館",
            placeholderImageName: "hatkobe_3",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.708589194409825, longitude: 135.21337999921263),
            subtitle: "横尾忠則ワールドが息づく",
            category: "アート",
            description: "兵庫県神戸市灘区にあるアーティスト 横尾忠則 の膨大な作品群を収蔵・展示する美術館です。ポスター・絵画・コラージュなど多彩な創作表現を通じて現代アートの魅力を体感できます。",
            pinColorName: "#00008B",
            imageURL: URL(string: "https://example.com/images/music_plaza_stage.png")
        ),
        Spot(
            id: "kobe-ice-campus",
            name: "Sysmex Kobe Ice Campus",
            placeholderImageName: "hatkobe_4",
            modelName: "Dragon_2.5_For_Animations.usdz",
            coordinate: CLLocationCoordinate2D(latitude: 34.698971647969785, longitude: 135.2138738394403),
            subtitle: "神戸のスケート文化を育む拠点",
            category: "スポーツ",
            description: "神戸市を拠点にスケートスポーツの普及・育成を推進する団体。年中利用可能なアイスリンクも開設し、初心者から競技選手まで幅広く支援しています。",
            pinColorName: "#32CD32",
            imageURL: URL(string: "https://example.com/images/monument_square.png")
        ),
    ]
}
