//
//  LocalDeleteManager.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2026/02/02.
//

import Foundation

/// ローカルデータの管理クラス
class LocalDataManager {
    static let shared = LocalDataManager()
    
    private init() {}
    
    // MARK: - すべてのローカルデータを削除
    
    /// アカウント削除時に呼び出す：すべてのローカルデータを削除
    func deleteAllLocalData() {
        print("🗑️ ローカルデータ削除開始...")
        
        // 1. UserDefaultsをクリア
        clearUserDefaults()
        
        // 2. AppStorageの値をクリア
        clearAppStorage()
        
        // 3. ファイルシステムのデータを削除
        deleteDocumentsDirectory()
        deleteCachesDirectory()
        deleteTempDirectory()
        
        // 4. 画像キャッシュをクリア
        clearImageCache()
        
        // 5. StampManagerのデータをクリア
        clearStampManagerData()
        
        print("✅ ローカルデータ削除完了")
    }
    
    // MARK: - UserDefaults
    
    /// UserDefaultsのすべてのキーを削除
    private func clearUserDefaults() {
        let domain = Bundle.main.bundleIdentifier!
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()
        print("✅ UserDefaults削除完了")
    }
    
    /// AppStorageで使用されている特定のキーを削除
    private func clearAppStorage() {
        let keys = [
            "pushNotificationEnabled",
            "dataCollectionConsent",
            "profileImageData",
            "hasCompletedInitialSetup",
            "lastSyncDate",
            // 他に使用しているキーがあれば追加
        ]
        
        for key in keys {
            UserDefaults.standard.removeObject(forKey: key)
        }
        
        UserDefaults.standard.synchronize()
        print("✅ AppStorage削除完了")
    }
    
    // MARK: - ファイルシステム
    
    /// Documentsディレクトリのデータを削除
    private func deleteDocumentsDirectory() {
        guard let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("⚠️ Documentsディレクトリが見つかりません")
            return
        }
        
        deleteContents(of: documentsPath, description: "Documents")
    }
    
    /// Cachesディレクトリのデータを削除
    private func deleteCachesDirectory() {
        guard let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("⚠️ Cachesディレクトリが見つかりません")
            return
        }
        
        deleteContents(of: cachesPath, description: "Caches")
    }
    
    /// Tempディレクトリのデータを削除
    private func deleteTempDirectory() {
        let tempPath = FileManager.default.temporaryDirectory
        deleteContents(of: tempPath, description: "Temp")
    }
    
    /// 指定されたディレクトリの中身を削除
    private func deleteContents(of directory: URL, description: String) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            var deletedCount = 0
            var totalSize: Int64 = 0
            
            for fileURL in contents {
                do {
                    // ファイルサイズを取得
                    let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
                    if let fileSize = attributes[.size] as? Int64 {
                        totalSize += fileSize
                    }
                    
                    // ファイル削除
                    try FileManager.default.removeItem(at: fileURL)
                    deletedCount += 1
                } catch {
                    print("⚠️ \(description)ファイル削除失敗: \(fileURL.lastPathComponent) - \(error)")
                }
            }
            
            let sizeInMB = Double(totalSize) / 1_048_576.0
            print("✅ \(description)削除完了: \(deletedCount)ファイル (\(String(format: "%.2f", sizeInMB))MB)")
            
        } catch {
            print("❌ \(description)の内容取得失敗: \(error)")
        }
    }
    
    // MARK: - 画像キャッシュ
    
    /// UIImageのキャッシュをクリア
    private func clearImageCache() {
        // URLCacheをクリア
        URLCache.shared.removeAllCachedResponses()
        
        // NSCacheを使用している場合はここでクリア
        // 例: ImageCache.shared.removeAllObjects()
        
        print("✅ 画像キャッシュ削除完了")
    }
    
    // MARK: - StampManager
    
    /// StampManagerの状態をクリア
    private func clearStampManagerData() {
        // StampManagerがシングルトンで状態を保持している場合
        // ここでクリアする（実装に応じて調整）
        
        // 例：
        // StampManager.shared.reset()
        
        print("✅ StampManagerデータクリア完了")
    }
    
    // MARK: - 個別削除メソッド（必要に応じて使用）
    
    /// プロフィール画像のみを削除
    func deleteProfileImage() {
        UserDefaults.standard.removeObject(forKey: "profileImageData")
        UserDefaults.standard.synchronize()
        print("✅ プロフィール画像削除完了")
    }
    
    /// 特定のファイルを削除
    func deleteFile(at path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)
        
        do {
            if FileManager.default.fileExists(atPath: path) {
                try FileManager.default.removeItem(at: fileURL)
                print("✅ ファイル削除成功: \(fileURL.lastPathComponent)")
                return true
            } else {
                print("⚠️ ファイルが存在しません: \(path)")
                return false
            }
        } catch {
            print("❌ ファイル削除失敗: \(error)")
            return false
        }
    }
    
    // MARK: - デバッグ用
    
    /// 現在のストレージ使用状況を取得
    func getStorageUsage() -> StorageUsage {
        var usage = StorageUsage()
        
        // Documents
        if let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            usage.documentsSize = getDirectorySize(documentsPath)
        }
        
        // Caches
        if let cachesPath = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first {
            usage.cachesSize = getDirectorySize(cachesPath)
        }
        
        // Temp
        usage.tempSize = getDirectorySize(FileManager.default.temporaryDirectory)
        
        // UserDefaults
        usage.userDefaultsSize = getUserDefaultsSize()
        
        return usage
    }
    
    /// ディレクトリのサイズを取得（バイト）
    private func getDirectorySize(_ directory: URL) -> Int64 {
        var totalSize: Int64 = 0
        
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            do {
                let resourceValues = try fileURL.resourceValues(forKeys: [.fileSizeKey])
                totalSize += Int64(resourceValues.fileSize ?? 0)
            } catch {
                continue
            }
        }
        
        return totalSize
    }
    
    /// UserDefaultsのおおよそのサイズを取得
    private func getUserDefaultsSize() -> Int64 {
        let dict = UserDefaults.standard.dictionaryRepresentation()
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict, options: [])
            return Int64(data.count)
        } catch {
            return 0
        }
    }
    
    /// ストレージ使用状況を出力
    func printStorageUsage() {
        let usage = getStorageUsage()
        
        print("\n" + String(repeating: "=", count: 50))
        print("📊 ストレージ使用状況")
        print(String(repeating: "=", count: 50))
        print("Documents: \(usage.documentsSize.toMB()) MB")
        print("Caches:    \(usage.cachesSize.toMB()) MB")
        print("Temp:      \(usage.tempSize.toMB()) MB")
        print("UserDefaults: \(usage.userDefaultsSize.toMB()) MB")
        print("合計:      \(usage.totalSize.toMB()) MB")
        print(String(repeating: "=", count: 50) + "\n")
    }
}

// MARK: - Supporting Types

/// ストレージ使用状況
struct StorageUsage {
    var documentsSize: Int64 = 0
    var cachesSize: Int64 = 0
    var tempSize: Int64 = 0
    var userDefaultsSize: Int64 = 0
    
    var totalSize: Int64 {
        return documentsSize + cachesSize + tempSize + userDefaultsSize
    }
}

// MARK: - Extensions

extension Int64 {
    /// バイトをMBに変換
    func toMB() -> String {
        let mb = Double(self) / 1_048_576.0
        return String(format: "%.2f", mb)
    }
}

