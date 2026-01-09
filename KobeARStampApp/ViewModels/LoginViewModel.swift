//
//  LoginViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/16.
//

import SwiftUI
import Supabase

@MainActor
class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    
    /// ログイン処理
    func signIn() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "メールアドレスとパスワードを入力してください。"
            showError = true
            return
        }
        
        isLoading = true
        
        do {
            // Supabaseでサインイン
            let session = try await SupabaseManager.shared.client.auth.signIn(
                email: email,
                password: password
            )
            
            print("✅ ログイン成功: \(session.user.id)")
            
            // AuthManagerに通知（これにより画面が切り替わります）
            await AuthManager.shared.handleSignInSuccess(user: session.user)
            
        } catch {
            print("❌ ログイン失敗: \(error)")
            print("❌ 記述: \(error.localizedDescription)")
            errorMessage = "ログインに失敗しました。\nメールアドレスかパスワードが間違っています。"
            showError = true
        }
        
        isLoading = false
    }
}
