//
//  AuthManager.swift
//  KobeARStampApp
//
//  認証状態を管理するクラス
//

import Foundation
import Supabase

class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var currentProfile: UserProfile?
    
    private let client = SupabaseManager.shared.client
    
    private init() {
        // アプリ起動時にセッションをチェック
        checkSession()
    }
    
    /// セッションの確認（同期版 - 初期化で使用）
    func checkSession() {
        if let session = client.auth.currentSession {
            isAuthenticated = true
            currentUser = session.user
            
            // プロフィールとスポットデータを取得
            Task {
                await loadUserData()
            }
        } else {
            isAuthenticated = false
            currentUser = nil
            currentProfile = nil
        }
    }
    
    /// ユーザーデータ（プロフィール・スポット等）を読み込み
    @MainActor
    private func loadUserData() async {
        // 1. プロフィール読み込み
        await loadUserProfile()
        
        // 2. スポットデータ読み込み
        await StampManager.shared.loadSpotsFromDatabase()
        
        // 3. 他のデータがあればここに追加
        // 例: await NotificationManager.shared.fetchNotifications()
        
        print("✅ ユーザーデータ読み込み完了")
    }
    
    /// ユーザープロフィールを読み込み
    @MainActor
    private func loadUserProfile() async {
        guard let userId = currentUser?.id else { return }
        
        do {
            let profile = try await DataRepository.shared.fetchUserProfile(userId: userId)
            currentProfile = profile
            print("✅ ユーザープロフィール読み込み成功")
        } catch {
            print("⚠️ ユーザープロフィール読み込み失敗: \(error)")
        }
    }
    
    /// サインイン後の処理
    @MainActor
    func handleSignInSuccess(user: User) async {
        currentUser = user
        isAuthenticated = true
        
        // ユーザーデータを読み込み（プロフィール + スポット）
        await loadUserData()
        
        // 認証状態変更を通知
        NotificationCenter.default.post(name: .authStateChanged, object: nil)
        
        print("✅ サインイン & データ読み込み完了: \(user.email ?? "Unknown")")
    }
    
    /// サインアウト
    @MainActor
    func signOut() async {
        do {
            try await DataRepository.shared.signOut()
            isAuthenticated = false
            currentUser = nil
            currentProfile = nil
            
            // 認証状態変更を通知
            NotificationCenter.default.post(name: .authStateChanged, object: nil)
            
            print("✅ サインアウト成功")
        } catch {
            print("❌ サインアウト失敗: \(error)")
        }
    }
}
