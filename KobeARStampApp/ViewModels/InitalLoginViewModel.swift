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
    
    let genders: [String] = ["", "男性", "女性", "その他", "回答しない"]
    let prefectures: [String] = [
        "",
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
                
                // user は非オプショナル
                let userId = authResponse.user.id
                
                // 2. handle_new_user トリガーが user_profile を作成するまで少し待つ
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
                
                // 3. トリガーで作成された user_profile を更新
                try await DataRepository.shared.updateUserProfile(
                    userId: userId,
                    gender: request.gender,
                    address: request.prefecture,
                    birthDate: request.birthDate
                )
                
                // 4. AuthManagerに認証状態を反映
                await AuthManager.shared.handleSignInSuccess(user: authResponse.user)
                
                // 5. 成功
                await MainActor.run {
                    self.isLoading = false
                    print("✅ サインアップ成功: \(request.email)")
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
