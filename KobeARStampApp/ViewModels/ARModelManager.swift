//
//  ARModelManager.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/17.
//

import SwiftUI
import Foundation

@MainActor
class ARModelManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = ARModelManager()
    
    // MARK: - Published Properties
    
    /// ダウンロード進捗 (0.0〜1.0)
    @Published var progress: Double = 0.0
    
    /// 同期状態メッセージ
    @Published var statusMessage: String = ""
    
    /// 同期中かどうか
    @Published var isSyncing: Bool = false
    
    /// エラー情報
    @Published var lastError: String?
    
    // MARK: - Private Properties
    
    private let modelsDirectory: URL
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {
        // ApplicationSupport/ARModels ディレクトリを作成
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        modelsDirectory = appSupport.appendingPathComponent("ARModels")
        
        // ディレクトリが存在しない場合は作成
        if !fileManager.fileExists(atPath: modelsDirectory.path) {
            try? fileManager.createDirectory(
                at: modelsDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        print("📁 ARモデルディレクトリ: \(modelsDirectory.path)")
    }
    
    // MARK: - Public API (差分チェック)
    
    /// DBとローカルを比較して、同期が必要かチェック
    /// - Parameter spots: Supabaseから取得したスポット + ARモデル情報
    /// - Returns: 同期が必要な場合 true
    func needsSync(with spots: [SpotWithModel]) async -> Bool {
        // 1. 期待されるファイル名のセット（arModel.idを使用）
        let expectedFiles = Set(spots.map { "\($0.arModel.id.uuidString).usdz" })
        
        // 2. ローカルの.usdzファイルを取得
        guard let localFiles = try? fileManager.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        ) else {
            // ディレクトリ読み取り失敗 → 同期必要
            print("⚠️ ローカルディレクトリの読み取り失敗")
            return true
        }
        
        let localFileNames = Set(localFiles
            .filter { $0.pathExtension == "usdz" }
            .map { $0.lastPathComponent }
        )
        
        // 3. 差分チェック
        let missingFiles = expectedFiles.subtracting(localFileNames)  // 不足しているファイル
        let extraFiles = localFileNames.subtracting(expectedFiles)    // 余分なファイル
        
        if !missingFiles.isEmpty {
            print("📥 不足しているモデル: \(missingFiles.count)個")
            for file in missingFiles {
                print("  - \(file)")
            }
        }
        
        if !extraFiles.isEmpty {
            print("🗑️ 削除が必要なモデル: \(extraFiles.count)個")
            for file in extraFiles {
                print("  - \(file)")
            }
        }
        
        let needsSync = !missingFiles.isEmpty || !extraFiles.isEmpty
        
        if needsSync {
            print("🔄 同期が必要です")
        } else {
            print("✅ ARモデルは最新です - 同期不要")
        }
        
        return needsSync
    }
    
    // MARK: - Public API (同期処理)
    
    /// ARモデルを同期（削除 → ダウンロード）
    /// - Parameter spots: Supabaseから取得したスポット + ARモデル情報
    /// - Throws: 同期エラー
    func syncModels(with spots: [SpotWithModel]) async throws {
        guard !isSyncing else {
            print("⚠️ 既に同期処理が実行中です")
            return
        }
        
        isSyncing = true
        progress = 0.0
        lastError = nil
        
        do {
            // 1. ホワイトリスト作成（期待されるファイル名のセット）
            let expectedFiles = Set(spots.map { "\($0.arModel.id.uuidString).usdz" })
            
            print("🔄 ARモデル同期開始: \(spots.count)個のモデル")
            
            // 2. ローカルファイルをクリーンアップ
            statusMessage = "不要なモデルを削除中..."
            try await cleanupLocalFiles(expectedFiles: expectedFiles)
            progress = 0.3
            
            // 3. 不足しているモデルをダウンロード
            statusMessage = "新しいモデルをダウンロード中..."
            try await downloadMissingModels(spots: spots)
            
            progress = 1.0
            statusMessage = "同期完了"
            print("✅ ARモデル同期完了")
            
        } catch {
            lastError = error.localizedDescription
            statusMessage = "同期エラー"
            print("❌ ARモデル同期エラー: \(error)")
            throw error
        }
        
        isSyncing = false
    }
    
    /// モデルファイルのローカルパスを取得
    /// - Parameter modelId: ARモデルID
    /// - Returns: ローカルファイルのURL
    func localURL(for modelId: UUID) -> URL {
        return modelsDirectory.appendingPathComponent("\(modelId.uuidString).usdz")
    }
    
    /// モデルが存在するか確認
    /// - Parameter modelId: ARモデルID
    /// - Returns: ファイルが存在する場合 true
    func modelExists(modelId: UUID) -> Bool {
        return fileManager.fileExists(atPath: localURL(for: modelId).path)
    }
    
    /// すべてのローカルモデルを削除（デバッグ用）
    func clearAllModels() throws {
        let files = try fileManager.contentsOfDirectory(at: modelsDirectory, includingPropertiesForKeys: nil)
        
        for file in files where file.pathExtension == "usdz" {
            try fileManager.removeItem(at: file)
            print("🗑️ 削除: \(file.lastPathComponent)")
        }
        
        print("✅ すべてのARモデルを削除しました")
    }
    
    // MARK: - Private Methods
    
    /// ホワイトリストに含まれないファイルを削除
    private func cleanupLocalFiles(expectedFiles: Set<String>) async throws {
        let localFiles = try fileManager.contentsOfDirectory(
            at: modelsDirectory,
            includingPropertiesForKeys: nil
        )
        
        var deletedCount = 0
        
        for fileURL in localFiles {
            let fileName = fileURL.lastPathComponent
            
            // .usdzファイルのみ対象
            guard fileName.hasSuffix(".usdz") else { continue }
            
            // ホワイトリストにないファイルは削除
            if !expectedFiles.contains(fileName) {
                try fileManager.removeItem(at: fileURL)
                deletedCount += 1
                print("🗑️ 削除: \(fileName)")
            }
        }
        
        if deletedCount > 0 {
            print("✅ \(deletedCount)個の古いモデルを削除しました")
        } else {
            print("ℹ️ 削除対象のモデルはありませんでした")
        }
    }
    
    /// 不足しているモデルを並列ダウンロード
    private func downloadMissingModels(spots: [SpotWithModel]) async throws {
        // ダウンロードが必要なスポットをフィルタ（arModel.idを使用）
        let spotsToDownload = spots.filter { spot in
            !modelExists(modelId: spot.arModel.id)
        }
        
        guard !spotsToDownload.isEmpty else {
            print("ℹ️ ダウンロードが必要なモデルはありません")
            return
        }
        
        print("📥 \(spotsToDownload.count)個のモデルをダウンロードします")
        
        let totalCount = spotsToDownload.count
        var completedCount = 0
        
        // TaskGroupで並列ダウンロード
        try await withThrowingTaskGroup(of: Void.self) { group in
            for spot in spotsToDownload {
                group.addTask {
                    try await self.downloadModel(spot: spot)
                    
                    // 進捗更新（メインスレッドで）
                    await MainActor.run {
                        completedCount += 1
                        self.progress = 0.3 + (0.7 * Double(completedCount) / Double(totalCount))
                        print("📥 進捗: \(completedCount)/\(totalCount)")
                    }
                }
            }
            
            // 全タスク完了を待つ
            try await group.waitForAll()
        }
        
        print("✅ すべてのモデルのダウンロードが完了しました")
    }
    
    /// 個別のモデルをダウンロード
    private func downloadModel(spot: SpotWithModel) async throws {
        // arModel.fileUrlを使用
        guard let url = URL(string: spot.arModel.fileUrl) else {
            throw ARModelError.invalidURL(spot.arModel.fileUrl)
        }
        
        // arModel.idを使用してローカルパスを決定
        let destinationURL = localURL(for: spot.arModel.id)
        
        // URLSessionでダウンロード
        let (tempURL, response) = try await URLSession.shared.download(from: url)
        
        // HTTPレスポンスチェック
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw ARModelError.downloadFailed(spot.name, httpResponse: response)
        }
        
        // 一時ファイルを移動
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: tempURL, to: destinationURL)
        
        print("✅ ダウンロード完了: \(spot.name) (\(spot.arModel.id.uuidString).usdz)")
    }
}

// MARK: - Errors

enum ARModelError: LocalizedError {
    case invalidURL(String)
    case downloadFailed(String, httpResponse: URLResponse?)
    case fileSystemError(String)
    case syncInProgress
    
    var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "無効なURL: \(url)"
        case .downloadFailed(let name, let response):
            if let httpResponse = response as? HTTPURLResponse {
                return "ダウンロード失敗: \(name) (HTTP \(httpResponse.statusCode))"
            }
            return "ダウンロード失敗: \(name)"
        case .fileSystemError(let message):
            return "ファイルエラー: \(message)"
        case .syncInProgress:
            return "既に同期処理が実行中です"
        }
    }
}

// MARK: - Debug Extension

#if DEBUG
extension ARModelManager {
    /// デバッグ用：ローカルモデル一覧を表示
    func listLocalModels() {
        do {
            let files = try fileManager.contentsOfDirectory(
                at: modelsDirectory,
                includingPropertiesForKeys: [.fileSizeKey]
            )
            
            print("\n" + String(repeating: "=", count: 60))
            print("📦 ローカルARモデル一覧")
            print(String(repeating: "=", count: 60))
            
            let usdzFiles = files.filter { $0.pathExtension == "usdz" }
            
            if usdzFiles.isEmpty {
                print("ℹ️ ローカルモデルはありません")
            } else {
                for file in usdzFiles {
                    let attributes = try? fileManager.attributesOfItem(atPath: file.path)
                    let size = attributes?[.size] as? Int64 ?? 0
                    let sizeString = ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
                    print("  • \(file.lastPathComponent) (\(sizeString))")
                }
                print("\n合計: \(usdzFiles.count)個")
            }
            
            print(String(repeating: "=", count: 60) + "\n")
        } catch {
            print("❌ ローカルモデル一覧の取得に失敗: \(error)")
        }
    }
}
#endif
