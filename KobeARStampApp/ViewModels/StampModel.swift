//
//  Spot.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import SwiftUI
import CoreLocation

/// スタンプラリーのスポット情報
struct Spot: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let placeholderImageName: String
    let modelName: String
    
    // 位置情報（追加）
    var coordinate: CLLocationCoordinate2D?
    var subtitle: String?
    var category: String?
    
    // カスタムイニシャライザ
    init(
        id: String,
        name: String,
        placeholderImageName: String,
        modelName: String,
        coordinate: CLLocationCoordinate2D? = nil,
        subtitle: String? = nil,
        category: String? = nil
    ) {
        self.id = id
        self.name = name
        self.placeholderImageName = placeholderImageName
        self.modelName = modelName
        self.coordinate = coordinate
        self.subtitle = subtitle
        self.category = category
    }
    
    // Hashableの実装
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatableの実装
    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id
    }
    
    // MARK: - Codable対応
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case placeholderImageName
        case modelName
        case latitude
        case longitude
        case subtitle
        case category
    }
    
    // カスタムデコーダー
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // 基本プロパティのデコード
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        placeholderImageName = try container.decode(String.self, forKey: .placeholderImageName)
        modelName = try container.decode(String.self, forKey: .modelName)
        subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        
        // 座標のデコード（緯度と経度が両方ある場合のみ）
        if let lat = try container.decodeIfPresent(Double.self, forKey: .latitude),
           let lon = try container.decodeIfPresent(Double.self, forKey: .longitude) {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            coordinate = nil
        }
    }
    
    // カスタムエンコーダー
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // 基本プロパティのエンコード
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(placeholderImageName, forKey: .placeholderImageName)
        try container.encode(modelName, forKey: .modelName)
        try container.encodeIfPresent(subtitle, forKey: .subtitle)
        try container.encodeIfPresent(category, forKey: .category)
        
        // 座標のエンコード（座標が存在する場合のみ）
        if let coord = coordinate {
            try container.encode(coord.latitude, forKey: .latitude)
            try container.encode(coord.longitude, forKey: .longitude)
        }
    }
}

// MARK: - AcquiredStamp

/// 取得済みスタンプの情報
struct AcquiredStamp: Identifiable, Codable {
    let id: UUID
    let spotID: String
    let imageFileName: String
    let acquiredDate: Date
}

// MARK: - Debug Extension

#if DEBUG
extension Spot {
    /// テスト用のサンプルスポット
    static let testSpot = Spot(
        id: "test-spot",
        name: "テストスポット",
        placeholderImageName: "spot_placeholder_1",
        modelName: "box.usdz",
        coordinate: CLLocationCoordinate2D(latitude: 34.69, longitude: 135.21),
        subtitle: "テスト用のスポット",
        category: "テスト"
    )
}
#endif
