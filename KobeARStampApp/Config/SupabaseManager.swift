import Foundation
import Supabase

/// Supabaseクライアントのシングルトン（セキュアバージョン）
class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Config.plistから認証情報を読み込む
        guard let config = SupabaseManager.loadConfig() else {
            fatalError("❌ Config.plistが見つかりません。Config.plist.exampleをコピーして設定してください。")
        }
        
        // ✅ 修正: 文字列をクリーンアップしてからURLに変換
        let cleanUrl = config.url
            .trimmingCharacters(in: .whitespacesAndNewlines)  // 前後の空白・改行を削除
            .replacingOccurrences(of: " ", with: "")          // 内部の空白も削除
        
        guard let url = URL(string: cleanUrl) else {
            // ✅ より詳しいエラー情報を表示
            print("❌ URL解析失敗")
            print("   元の文字列: [\(config.url)]")
            print("   クリーン後: [\(cleanUrl)]")
            print("   文字数: \(cleanUrl.count)")
            print("   バイト表現: \(Array(cleanUrl.utf8))")
            fatalError("❌ Supabase URLが無効です: \"\(cleanUrl)\"")
        }
        
        self.client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: config.anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        
        print("✅ Supabase接続: \(cleanUrl)")
    }
    
    // MARK: - Config読み込み
    
    private static func loadConfig() -> SupabaseConfig? {
        // Config.plistのパスを取得
        guard let path = Bundle.main.path(forResource: "Config", ofType: "plist") else {
            print("❌ Config.plistが見つかりません")
            print("   パス確認: \(Bundle.main.bundlePath)")
            return nil
        }
        
        print("✅ Config.plist発見: \(path)")
        
        guard let xml = FileManager.default.contents(atPath: path) else {
            print("❌ Config.plistの読み込みに失敗")
            return nil
        }
        
        guard let plist = try? PropertyListSerialization.propertyList(
            from: xml,
            options: .mutableContainersAndLeaves,
            format: nil
        ) as? [String: String] else {
            print("❌ Config.plistのパースに失敗")
            return nil
        }
        
        // デバッグ: plistの内容を表示
        print("📄 Config.plistの内容:")
        for (key, value) in plist {
            // キーの長さをチェック（隠れた文字を検出）
            let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
            print("   \(key): [\(trimmedValue)] (長さ: \(value.count) → \(trimmedValue.count))")
        }
        
        // 必須キーのチェック
        guard let url = plist["SUPABASE_URL"],
              let anonKey = plist["SUPABASE_ANON_KEY"],
              !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !anonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ Config.plistの必須キーが不足しています")
            return nil
        }
        
        let trimmedUrl = url.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = anonKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // デフォルト値チェック
        if trimmedUrl.contains("YOUR_") || trimmedKey.contains("YOUR_") {
            print("❌ Config.plistがまだテンプレートのままです")
            print("   URL: \(trimmedUrl)")
            return nil
        }
        
        return SupabaseConfig(url: trimmedUrl, anonKey: trimmedKey)
    }
}

// MARK: - Config構造体

private struct SupabaseConfig {
    let url: String
    let anonKey: String
}

// MARK: - デバッグ用ヘルパー

#if DEBUG
extension SupabaseManager {
    /// 設定が正しく読み込まれているか確認
    static func validateConfig() -> Bool {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 Config.plist 検証開始")
        print(String(repeating: "=", count: 60))
        
        guard let config = loadConfig() else {
            print("❌ 設定の読み込みに失敗")
            print(String(repeating: "=", count: 60) + "\n")
            return false
        }
        
        print("\n✅ 設定の読み込み成功")
        print("   URL: \(config.url)")
        print("   Key: \(config.anonKey.prefix(30))...[残り\(config.anonKey.count - 30)文字]")
        
        // URL形式の検証
        if let _ = URL(string: config.url) {
            print("✅ URLの形式が正しい")
        } else {
            print("❌ URLの形式が不正")
            print("   バイト表現: \(Array(config.url.utf8))")
        }
        
        // Keyの長さチェック（通常200文字以上）
        if config.anonKey.count > 100 {
            print("✅ Anon Keyの長さが適切")
        } else {
            print("⚠️  Anon Keyが短すぎる可能性があります（\(config.anonKey.count)文字）")
        }
        
        print(String(repeating: "=", count: 60) + "\n")
        return true
    }
}
#endif
