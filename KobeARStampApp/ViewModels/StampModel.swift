//
//  Spot.swift
//  KobeARStampApp
//
//  Supabase DB連携対応版（完全版）
//

import SwiftUI
import Foundation
import CoreLocation
/// A data structure representing a single AR spot.

/// スタンプラリーのスポット情報（DB連携版）
/// DBの spots テーブルに完全対応
struct Spot: Identifiable, Codable, Equatable, Hashable {
    // MARK: - DB Properties (spots テーブルの全カラム)
    
    let id: UUID
    let name: String

    let subtitle: String?
    let description: String
    let address: String
    let latitude: Double  // numeric(10,7)
    let longitude: Double // numeric(10,7)
    let radius: Int?
    let category: String?
    let pinColor: String?        // pin_color (HEXコード)
    let imageUrl: String?        // image_url
    let arModelId: UUID?         // ar_model_id
    let isActive: Bool           // is_active (デフォルト: false)
    let createdByUser: UUID?     // created_by_user
    let createdAt: Date          // created_at
    let updatedAt: Date?         // updated_at
    let deletedAt: Date?         // deleted_at
    
    // MARK: - Computed Properties (ローカル専用)
    
    /// プレースホルダー画像名（ローカルアセット用）
    var placeholderImageName: String {
        // カテゴリに応じて画像名を決定
        switch category {
        case "観光": return "spot_placeholder_1"
        case "飲食": return "spot_placeholder_2"
        case "歴史": return "spot_placeholder_3"
        case "公園": return "spot_placeholder_1"
        case "文化": return "spot_placeholder_2"
        case "アート": return "spot_placeholder_3"
        case "教育": return "spot_placeholder_1"
        case "娯楽": return "spot_placeholder_2"
        case "スポーツ": return "spot_placeholder_3"
        default: return "spot_placeholder_default"
        }

    }
    
    /// ARモデルファイル名（ローカルアセット用）
    /// 実際にはDBのar_modelテーブルから取得したfileUrlを使う
    var modelName: String {
        return arModelId != nil ? "model_\(id.uuidString).usdz" : "box.usdz"
    }
    
    /// 座標（CLLocationCoordinate2D形式）
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// 画像URL（URL型）
    var imageURL: URL? {
        guard let imageUrl = imageUrl else { return nil }
        return URL(string: imageUrl)
    }
    
    /// ピンの色（SwiftUI Color）
    var pinColorValue: Color {
        Color(hex: pinColor ?? "#FF0000") ?? .red
    }
    
    /// 表示用のID文字列（デバッグ・表示用）
    var displayId: String {
        id.uuidString
    }
    
    /// 短縮ID（デバッグ用）
    var shortId: String {
        String(id.uuidString.prefix(8))
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case subtitle
        case description
        case address
        case latitude
        case longitude
        case radius
        case category
        case pinColor = "pin_color"
        case imageUrl = "image_url"
        case arModelId = "ar_model_id"
        case isActive = "is_active"
        case createdByUser = "created_by_user"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case deletedAt = "deleted_at"
    }
    

    // MARK: - Equatable & Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Spot, rhs: Spot) -> Bool {
        lhs.id == rhs.id

    }

}


// MARK: - Debug Extension

#if DEBUG
extension Spot {
    /// テスト用のサンプルスポット
    static let testSpot = Spot(

        id: UUID(),
        name: "神戸ポートタワー",
        subtitle: "神戸のシンボル",
        description: "神戸港を見渡せる展望タワーです",
        address: "兵庫県神戸市中央区波止場町5-5",
        latitude: 34.6829,
        longitude: 135.1862,
        radius: 50,
        category: "観光",
        pinColor: "#FF0000",
        imageUrl: "https://example.com/port-tower.jpg",
        arModelId: nil,
        isActive: true,
        createdByUser: nil,
        createdAt: Date(),
        updatedAt: nil,
        deletedAt: nil

    )
    
    static let testSpots: [Spot] = [
        testSpot,
        Spot(
            id: UUID(),
            name: "メリケンパーク",
            subtitle: "海辺の公園",
            description: "神戸港に面した美しい公園",
            address: "兵庫県神戸市中央区波止場町2-2",
            latitude: 34.6825,
            longitude: 135.1870,
            radius: 100,
            category: "公園",
            pinColor: "#0000FF",
            imageUrl: nil,
            arModelId: nil,
            isActive: true,
            createdByUser: nil,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil
        ),
        Spot(
            id: UUID(),
            name: "南京町",
            subtitle: "中華街",
            description: "日本三大中華街のひとつ",
            address: "兵庫県神戸市中央区栄町通",
            latitude: 34.6887,
            longitude: 135.1915,
            radius: 80,
            category: "飲食",
            pinColor: "#FFFF00",
            imageUrl: nil,
            arModelId: nil,
            isActive: true,
            createdByUser: nil,
            createdAt: Date(),
            updatedAt: nil,
            deletedAt: nil
        )
    ]
}
#endif
