////
////  mockPins.swift
////  KobeARStampApp
////
////  Created by 大江悠都 on 2025/07/07.
////
//
//import Foundation
//import CoreLocation
//
//let mockPins: [CustomPin] = [
//    // ========== 灘駅周辺（灘駅を中心に配置、各ピン間は概ね200m以上） ==========
//    CustomPin(
//        id: UUID(),
//        title: "灘駅北口広場",
//        subtitle: "灘駅北側の待ち合わせ広場",
//        coordinate: CLLocationCoordinate2D(latitude: 34.70622423097614,  longitude: 135.21616725739096),
//        pinColorName: "#FF0000", // レッド
//        imageURL: URL(string: "https://example.com/images/nada_north_plaza.png"),
//        description: "灘駅の北口にある広場。集合や待ち合わせに便利なスポットです。",
//        category: "公園",
//        createdAt: Date(timeIntervalSince1970: 1_689_000_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "敏馬神社社殿",
//        subtitle: "海風香る縁切りの社、灘の水神・敏馬神社（みぬめじんじゃ）",
//        coordinate: CLLocationCoordinate2D(latitude: 34.70344357985072,  longitude: 135.21879732451967),
//        pinColorName: "#0000FF", // ブルー
//        imageURL: URL(string: "https://example.com/images/nada_south_cafe.png"),
//        description: "敏馬神社は、灘区の海沿いに位置する歴史ある神社です。古くから水神を祀り、漁業や航海の守護とともに、縁切りの神としても知られています。海風に包まれ、灘の人々の信仰と文化を今に伝える神社です。",
//        category: "文化",
//        createdAt: Date(timeIntervalSince1970: 1_689_000_050),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "なぎさ公園",
//        subtitle: "海風とアートが彩るなぎさ公園",
//        coordinate: CLLocationCoordinate2D(latitude: 34.6970625279125,  longitude: 135.21454865587015),
//        pinColorName: "#00FF00", // グリーン
//        imageURL: URL(string: "https://example.com/images/nada_central_park.png"),
//        description: "なぎさ公園は灘区の海沿いに広がる都市公園で、芝生広場やウォーキングコース、アートモニュメントが楽しめる憩いの場です。",
//        category: "公園",
//        createdAt: Date(timeIntervalSince1970: 1_689_020_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "西郷河川公園",
//        subtitle: "川のそばでバスケも遊びも ― 西郷川河口公園",
//        coordinate: CLLocationCoordinate2D(latitude: 34.702412041570284,  longitude: 135.22474839795566),
//        pinColorName: "#FFFF00", // イエロー
//        imageURL: URL(string: "https://example.com/images/rokkodo_gallery.png"),
//        description: "住宅街にひっそり佇む 西郷川河口公園 は、河口ならではの開放感と桜が楽しめる小さな都市公園。バスケットゴールも３箇所あり、遊びとくつろぎが両立する場所です。",
//        category: "公園",
//        createdAt: Date(timeIntervalSince1970: 1_689_050_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "ミュージアムロード",
//        subtitle: "文化が連なるアート街道",
//        coordinate: CLLocationCoordinate2D(latitude: 34.701138596503135,  longitude: 135.2180575627066),
//        pinColorName: "#FFA500", // オレンジ
//        imageURL: URL(string: "https://example.com/images/oji_park_area.png"),
//        description: "兵庫県立美術館から神戸市立王子動物園まで約1.2 kmにわたる散策路。多彩な美術館・動物園・パブリックアートが並び、灘区の “芸術と文化の軸” を体感できます。",
//        category: "アート",
//        createdAt: Date(timeIntervalSince1970: 1_689_080_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "兵庫県立美術館",
//        subtitle: "海辺に佇むモダンアートの殿堂",
//        coordinate: CLLocationCoordinate2D(latitude: 34.69938435220899,  longitude: 135.21824370509106),
//        pinColorName: "#00FFFF", // シアン
//        imageURL: URL(string: "https://example.com/images/coast_walk_view.png"),
//        description: "世界的建築家 安藤忠雄 設計による建築美と現代アートが融合するギャラリー空間です。家族や大人も楽しめる展覧会や教育プログラムも充実しています。",
//        category: "アート",
//        createdAt: Date(timeIntervalSince1970: 1_689_100_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "ひょうご震災記念21世紀研究機構",
//        subtitle: "震災の記憶を未来のしあわせへ紡ぐ研究機構",
//        coordinate: CLLocationCoordinate2D(latitude: 34.699200000000, longitude: 135.216300000000),
//        pinColorName: "#800080", // パープル
//        imageURL: URL(string: "https://example.com/images/hat_art_south.png"),
//        description: "阪神・淡路大震災を契機に、地域の安心・人のケア・共生社会の実現に向けて調査研究を行い、知見を社会に届ける専門機関です。",
//        category: "教育",
//        createdAt: Date(timeIntervalSince1970: 1_689_120_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "王子動物園",
//        subtitle: "六甲山麓に広がる、自然と動物のふれあい公園",
//        coordinate: CLLocationCoordinate2D(latitude: 34.70978782499848,  longitude: 135.21521542400927),
//        pinColorName: "#FF00FF", // マゼンタ
//        imageURL: URL(string: "https://example.com/images/hat_coast_north.png"),
//        description: "約120種700点以上の動物たちが暮らし、コアラやゾウ、フラミンゴなど様々な動物を観察できます。遊園地や旧ハンター住宅などの歴史的建造物も併設され、家族連れにも楽しめるスポットです。",
//        category: "娯楽",
//        createdAt: Date(timeIntervalSince1970: 1_689_140_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "横尾忠則現代美術館",
//        subtitle: "横尾忠則ワールドが息づく現代美術館",
//        coordinate: CLLocationCoordinate2D(latitude: 34.708589194409825,  longitude: 135.21337999921263),
//        pinColorName: "#00008B", // ネイビーブルー
//        imageURL: URL(string: "https://example.com/images/music_plaza_stage.png"),
//        description: "兵庫県神戸市灘区にあるアーティスト 横尾忠則 の膨大な作品群を収蔵・展示する美術館です。ポスター・絵画・コラージュなど多彩な創作表現を通じて現代アートの魅力を体感できます。",
//        category: "アート",
//        createdAt: Date(timeIntervalSince1970: 1_689_160_000),
//        updatedAt: nil
//    ),
//    CustomPin(
//        id: UUID(),
//        title: "Sysmex Kobe Ice Campus",
//        subtitle: "神戸のスケート文化を育む拠点",
//        coordinate: CLLocationCoordinate2D(latitude: 34.698971647969785,  longitude: 135.2138738394403),
//        pinColorName: "#32CD32", // ライムグリーン
//        imageURL: URL(string: "https://example.com/images/monument_square.png"),
//        description: "神戸市を拠点にスケートスポーツの普及・育成を推進する団体。年中利用可能なアイスリンクも開設し、初心者から競技選手まで幅広く支援しています。",
//        category: "スポーツ",
//        createdAt: Date(timeIntervalSince1970: 1_689_180_000),
//        updatedAt: nil
//    ),
//]
