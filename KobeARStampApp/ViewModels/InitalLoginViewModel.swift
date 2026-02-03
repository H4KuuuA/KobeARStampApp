//
//  InitialLoginViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import SwiftUI

class InitialLoginViewModel: ObservableObject {
    @Published var selectedBirthDate: Date?
    @Published var selectedGender: String = ""
    @Published var selectedPrefecture: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let genders: [String] = ["男性", "女性", "その他", "回答しない"]
    let prefectures: [String] = [
        "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県",
        "岐阜県", "静岡県", "愛知県", "三重県",
        "滋賀県", "京都府", "大阪府", "兵庫県", "奈良県", "和歌山県",
        "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県",
        "福岡県", "佐賀県", "長崎県", "熊本県", "大分県", "宮崎県", "鹿児島県",
        "沖縄県"
    ]
    
    /// 新規登録（Supabase Auth + user_profile）
    /// リトライ処理付き：handle_new_userトリガーの発火を待機
    func signUp(request: SignUpRequest, completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // 1. Supabase Auth でサインアップ
                let authResponse = try await DataRepository.shared.signUp(
                    email: request.email,
                    password: request.password
                )
                
                let userId = authResponse.user.id
                print("✅ Supabase Auth サインアップ成功: \(request.email) (ID: \(userId))")
                
                // 2. handle_new_user トリガーが user_profile を作成するまで待機（リトライ）
                let profileCreated = try await waitForUserProfileCreation(userId: userId, maxRetries: 10)
                
                if !profileCreated {
                    // トリガーが発火しなかった場合、手動で作成
                    print("⚠️ handle_new_userトリガー未発火 → 手動でuser_profile作成")
                    try await createUserProfileManually(userId: userId, email: request.email)
                }
                
                // 3. user_profileを追加情報で更新
                try await DataRepository.shared.updateUserProfile(
                    userId: userId,
                    gender: request.gender,
                    address: request.prefecture.isEmpty ? nil : request.prefecture,
                    birthDate: request.birthDate  // nilの場合もあり得る
                )
                print("✅ user_profile更新完了")
                
                // 4. AuthManagerに認証状態を反映
                await AuthManager.shared.handleSignInSuccess(user: authResponse.user)
                
                // 5. 成功
                await MainActor.run {
                    self.isLoading = false
                    print("✅ サインアップ完全成功: \(request.email)")
                }
                completion(true)
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = self.parseError(error)
                    print("❌ サインアップ失敗: \(error)")
                }
                completion(false)
            }
        }
    }
    
    /// user_profileの作成を待機（リトライ処理）
    /// - Parameters:
    ///   - userId: ユーザーID
    ///   - maxRetries: 最大リトライ回数
    /// - Returns: 作成成功したらtrue、タイムアウトしたらfalse
    private func waitForUserProfileCreation(userId: UUID, maxRetries: Int = 10) async throws -> Bool {
        for attempt in 1...maxRetries {
            // 0.5秒待機
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // プロフィールが作成されたか確認
            do {
                _ = try await DataRepository.shared.fetchUserProfile(userId: userId)
                print("✅ user_profile作成確認成功（\(attempt)回目）")
                return true
            } catch {
                print("⏳ user_profile作成待機中...（\(attempt)/\(maxRetries)回目）")
                
                // 最後のリトライ以外はエラーを無視
                if attempt == maxRetries {
                    print("⚠️ user_profile作成タイムアウト（\(maxRetries)回試行）")
                    return false
                }
            }
        }
        return false
    }
    
    /// 手動でuser_profileを作成（トリガー未発火時のフォールバック）
    private func createUserProfileManually(userId: UUID, email: String) async throws {
        // DataRepository経由でuser_profileを作成
        struct ProfileInsert: Encodable {
            let user_id: String
            let email: String
            let role: String
            let is_active: Bool
            let last_login_at: String
        }
        
        let formatter = ISO8601DateFormatter()
        let insert = ProfileInsert(
            user_id: userId.uuidString,
            email: email,
            role: "user",
            is_active: true,
            last_login_at: formatter.string(from: Date())
        )
        
        // DataRepositoryのclientは外部からアクセスできないため、
        // SupabaseManagerを直接使用
        try await SupabaseManager.shared.client
            .from("user_profile")
            .insert(insert)
            .execute()
        
        print("✅ user_profile手動作成完了")
    }
    
    /// エラーメッセージをパース
    private func parseError(_ error: Error) -> String {
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("email") && errorString.contains("already") {
            return "このメールアドレスは既に登録されています"
        } else if errorString.contains("password") && errorString.contains("weak") {
            return "パスワードが弱すぎます。6文字以上で入力してください"
        } else if errorString.contains("invalid") && errorString.contains("email") {
            return "メールアドレスの形式が正しくありません"
        } else if errorString.contains("network") {
            return "ネットワークエラーが発生しました"
        } else {
            return "登録に失敗しました。もう一度お試しください"
        }
    }
}
