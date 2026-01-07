//
//  SpotWithModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/17.
//

import Foundation

/// Supabaseから取得するSpotとARModelの結合データ
/// spots テーブルと ar_model テーブルを JOIN したクエリ結果を格納
struct SpotWithModel: Decodable, Identifiable {
    let id: UUID
    let name: String
    let arModelId: UUID
    let arModel: ARModelInfo
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case arModelId = "ar_model_id"
        case arModel = "ar_model"
    }
}

/// ARモデルの情報（Supabase の ar_model テーブル）
struct ARModelInfo: Decodable {
    let id: UUID
    let fileUrl: String
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case fileUrl = "file_url"
        case updatedAt = "updated_at"
    }
}

// MARK: - Debug Extension

#if DEBUG
extension SpotWithModel {
    /// テスト用のサンプルデータ
    static let testData = SpotWithModel(
        id: UUID(),
        name: "神戸ポートタワー",
        arModelId: UUID(),
        arModel: ARModelInfo(
            id: UUID(),
            fileUrl: "https://example.com/models/port-tower.usdz",
            updatedAt: Date()
        )
    )
}
#endif
