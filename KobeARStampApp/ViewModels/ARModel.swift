//
//  ARModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/16.
//

import SwiftUI

/// ARモデル情報（DB連携版）
/// DBの ar_model テーブルに完全対応
struct ARModel: Identifiable, Codable, Equatable, Hashable {
    // MARK: - DB Properties (ar_model テーブルの全カラム)
    
    let id: UUID
    let modelName: String        // model_name
    let fileUrl: String          // file_url
    let thumbnailUrl: String?    // thumbnail_url
    let description: String?
    let fileSize: Int?           // file_size (bigint)
    let fileType: String?        // file_type
    let createdByUserId: UUID    // created_by_user_id
    let createdAt: Date          // created_at
    let updatedAt: Date?         // updated_at
    
    // MARK: - Computed Properties (ローカル専用)
    
    /// ファイルURL（URL型）
    var fileURL: URL? {
        URL(string: fileUrl)
    }
    
    /// サムネイルURL（URL型）
    var thumbnailURL: URL? {
        guard let thumbnailUrl = thumbnailUrl else { return nil }
        return URL(string: thumbnailUrl)
    }
    
    /// プレースホルダー画像名（ローカルアセット用）
    var placeholderImageName: String {
        return "ar_model_placeholder_default"
    }
    
    /// 表示用のID文字列（デバッグ・表示用）
    var displayId: String {
        id.uuidString
    }
    
    /// 短縮ID（デバッグ用）
    var shortId: String {
        String(id.uuidString.prefix(8))
    }
    
    /// ファイルサイズの表示用文字列
    var displayFileSize: String {
        guard let fileSize = fileSize else { return "不明" }
        
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(fileSize))
    }
    
    /// ファイル拡張子
    var fileExtension: String {
        (fileUrl as NSString).pathExtension.lowercased()
    }
    
    /// USDZファイルかどうか
    var isUSDZ: Bool {
        fileExtension == "usdz"
    }
    
    /// Realityファイルかどうか
    var isReality: Bool {
        fileExtension == "reality"
    }
    
    // MARK: - Codable Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case modelName = "model_name"
        case fileUrl = "file_url"
        case thumbnailUrl = "thumbnail_url"
        case description
        case fileSize = "file_size"
        case fileType = "file_type"
        case createdByUserId = "created_by_user_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // MARK: - Equatable & Hashable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ARModel, rhs: ARModel) -> Bool {
        lhs.id == rhs.id
    }
}


// MARK: - Loader Utilities

extension ARModel {
    /// URL文字列がHTTP(S)か、バンドル内ファイル名かを自動判別してURLを返す
    /// - Throws: URL解決に失敗した場合
    func resolvedURL() throws -> URL {
        // 明示的なURLとして解釈できる場合（http/https）
        if let url = URL(string: fileUrl), let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" {
            return url
        }
        
        // バンドル内のファイル名として解釈（拡張子が含まれていてもOK）
        let name = (fileUrl as NSString).deletingPathExtension
        let ext = (fileUrl as NSString).pathExtension
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: ext.isEmpty ? nil : ext) {
            return bundleURL
        }
        
        // どちらでも解決できない場合はエラー
        throw URLError(.badURL)
    }
    
    /// 解決済みURLから拡張子（小文字）を返す。解決できない場合は `fileExtension` を返す
    var resolvedFileExtension: String {
        (try? resolvedURL().pathExtension.lowercased()) ?? fileExtension
    }
    
    enum FileKind { case usdz, reality, other }
    
    /// 解決済み拡張子に基づくファイル種別
    var resolvedKind: FileKind {
        switch resolvedFileExtension {
        case "usdz": return .usdz
        case "reality": return .reality
        default: return .other
        }
    }
}
 
 
// MARK: - Debug Extension
 
#if DEBUG
extension ARModel {
    /// テスト用のサンプルARモデル
    static let testModel = ARModel(
        id: UUID(),
        modelName: "神戸ポートタワー3Dモデル",
        fileUrl: "https://example.com/models/port-tower.usdz",
        thumbnailUrl: "https://example.com/thumbnails/port-tower.jpg",
        description: "神戸ポートタワーの詳細な3Dモデル",
        fileSize: 5_242_880, // 5MB
        fileType: "model/vnd.usdz+zip",
        createdByUserId: UUID(),
        createdAt: Date(),
        updatedAt: nil
    )
    
    static let testModels: [ARModel] = [
        testModel,
        ARModel(
            id: UUID(),
            modelName: "メリケンパークモニュメント",
            fileUrl: "https://example.com/models/meriken-park.usdz",
            thumbnailUrl: nil,
            description: "メリケンパークのモニュメント",
            fileSize: 3_145_728, // 3MB
            fileType: "model/vnd.usdz+zip",
            createdByUserId: UUID(),
            createdAt: Date(),
            updatedAt: nil
        ),
        ARModel(
            id: UUID(),
            modelName: "南京町門",
            fileUrl: "https://example.com/models/nankinmachi-gate.reality",
            thumbnailUrl: "https://example.com/thumbnails/nankinmachi-gate.jpg",
            description: "南京町の門",
            fileSize: 7_340_032, // 7MB
            fileType: "application/octet-stream",
            createdByUserId: UUID(),
            createdAt: Date(),
            updatedAt: nil
        )
    ]
}
#endif  
