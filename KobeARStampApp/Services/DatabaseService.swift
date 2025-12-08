import Foundation

class DatabaseService {
    static let shared = DatabaseService()
    
    private init() {}
    
    // Supabase設定（環境変数や設定ファイルから読み込むことを推奨）
    private let supabaseURL = "https://your-project.supabase.co/rest/v1/user_profiles"
    private let supabaseKey = "YOUR_SUPABASE_ANON_KEY"
    
    // デバッグモード：trueにするとDB接続をスキップしてローカルのみで動作
    private let debugMode = true
    
    func saveUserProfile(_ profile: UserProfile, completion: @escaping (Result<Void, Error>) -> Void) {
        // デバッグモード：DB接続なしでテスト
        if debugMode {
            print("⚠️ デバッグモード: DB保存をスキップしました")
            print("保存データ: \(profile.toDictionary())")
            
            // 1秒後に成功を返す（ネットワーク遅延をシミュレート）
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                completion(.success(()))
            }
            return
        }
        
        // 本番モード：実際のSupabase接続
        guard let url = URL(string: supabaseURL) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        
        let body = profile.toDictionary()
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 201 {
                    completion(.success(()))
                } else {
                    let error = NSError(
                        domain: "Supabase Error",
                        code: httpResponse.statusCode,
                        userInfo: [NSLocalizedDescriptionKey: "ステータスコード: \(httpResponse.statusCode)"]
                    )
                    completion(.failure(error))
                }
            }
        }.resume()
    }
}
