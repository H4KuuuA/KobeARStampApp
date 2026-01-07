//
//  AppLoaderViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/26.
//

import SwiftUI

@MainActor
class AppLoaderViewModel: ObservableObject {
    @Published var isLoading = true
    @Published var loadingMessage = "読み込み中..."
    @Published var showError = false
    @Published var errorMessage: String?
    
    private var minLoadingTime: TimeInterval = 1.5
    
    // MARK: - ログイン後の差分チェック & 必要時のみ同期
    
    /// DBと比較して差異がある場合のみ同期、差異がない場合もプログレスバーを100%にしてから遷移
    func checkAndSyncIfNeeded() async {
        loadingMessage = "データを確認中..."
        
        // UI更新を確実に反映させるため、少し待機
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
        
        do {
            print("🔍 ARモデル差分チェック開始...")
            
            // 1. Supabaseから最新のスポット + ARモデル情報を取得
            let spots = try await DataRepository.shared.fetchSpotsWithARModels()
            
            // 2. ローカルと比較して同期が必要か確認
            let needsSync = await ARModelManager.shared.needsSync(with: spots)
            
            if !needsSync {
                // ✅ 差分なし → プログレスバーを100%にしてからHomeViewへ
                print("✅ ARモデルは最新です - 同期不要")
                loadingMessage = "準備完了"
                
                // プログレスバーを100%まで到達させる
                await animateProgressToComplete()
                
                // 最低表示時間を確保（UX向上）
                try? await Task.sleep(nanoseconds: UInt64(minLoadingTime * 1_000_000_000))
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    isLoading = false
                }
                return
            }
            
            // 3. 差分あり → 同期開始（プログレスバーは自動で更新される）
            print("🔄 差分検出 - 同期を開始します")
            await syncModelsWithLoading(spots)
            
        } catch {
            print("⚠️ 差分チェック失敗: \(error)")
            errorMessage = "ARモデルの確認に失敗しました"
            showError = true
            
            // エラーでもプログレスバーを100%にしてからHomeViewへ
            await animateProgressToComplete()
            
            // 最低表示時間を確保してからHomeViewへ
            try? await Task.sleep(nanoseconds: UInt64(minLoadingTime * 1_000_000_000))
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = false
            }
        }
    }
    
    // MARK: - プログレスバーを100%にアニメーション
    
    /// プログレスバーを現在値から100%まで滑らかにアニメーション
    private func animateProgressToComplete() async {
        let startProgress = ARModelManager.shared.progress
        let duration: TimeInterval = 0.8 // アニメーション時間
        let steps = 20 // アニメーションのステップ数
        let stepDuration = duration / Double(steps)
        
        for i in 1...steps {
            let progress = startProgress + (1.0 - startProgress) * (Double(i) / Double(steps))
            ARModelManager.shared.progress = progress
            
            try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
        }
        
        // 最終的に確実に100%にする
        ARModelManager.shared.progress = 1.0
        
        // 100%表示を少し維持
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3秒
    }
    
    // MARK: - Loading表示付き同期処理
    
    /// LoadingViewを表示してARモデルを同期
    private func syncModelsWithLoading(_ spots: [SpotWithModel]) async {
        let startTime = Date()
        
        // メッセージ更新（LoadingViewは既に表示されている）
        loadingMessage = "ARモデルを同期中..."
        
        print("🔄 同期開始")
        
        do {
            // ARモデルを同期（削除 + ダウンロード）
            // ⚠️ この中でARModelManager.shared.progressが自動更新される
            try await ARModelManager.shared.syncModels(with: spots)
            
            loadingMessage = "同期完了"
            print("✅ ARモデル同期完了")
            
        } catch {
            print("⚠️ ARモデル同期失敗: \(error)")
            loadingMessage = "同期完了"
            errorMessage = "一部のARモデルを同期できませんでした"
            showError = true
            
            // エラーでもプログレスバーを100%に
            await animateProgressToComplete()
        }
        
        // 同期完了後、プログレスバーが100%未満の場合は100%まで到達させる
        if ARModelManager.shared.progress < 1.0 {
            await animateProgressToComplete()
        }
        
        // 最低表示時間を確保（UX向上）
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed < minLoadingTime {
            try? await Task.sleep(nanoseconds: UInt64((minLoadingTime - elapsed) * 1_000_000_000))
        }
        
        // ローディング終了
        withAnimation(.easeInOut(duration: 0.5)) {
            self.isLoading = false
        }
        
        print("✅ LoadingView非表示 - HomeViewへ遷移")
    }
    
    // MARK: - バックグラウンド差分チェック（HomeView表示後）
    
    /// HomeView表示後、バックグラウンドで差分チェック（差分がある場合のみLoadingView表示）
    func checkAndSyncInBackground() async {
        do {
            print("🔍 [バックグラウンド] ARモデル差分チェック開始...")
            
            // 1. Supabaseから最新のスポット + ARモデル情報を取得
            let spots = try await DataRepository.shared.fetchSpotsWithARModels()
            
            // 2. ローカルと比較して同期が必要か確認
            let needsSync = await ARModelManager.shared.needsSync(with: spots)
            
            if !needsSync {
                print("✅ ARモデルは最新です - 同期不要")
                return
            }
            
            // 3. 差分あり → LoadingViewを表示して同期開始
            print("🔄 差分検出 - LoadingViewを表示して同期開始")
            
            // プログレスをリセット
            ARModelManager.shared.progress = 0.0
            
            // LoadingViewを表示
            withAnimation(.easeInOut(duration: 0.3)) {
                isLoading = true
                loadingMessage = "ARモデルを同期中..."
            }
            
            // UI更新を確実に反映
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1秒
            
            let startTime = Date()
            
            do {
                try await ARModelManager.shared.syncModels(with: spots)
                loadingMessage = "同期完了"
                print("✅ ARモデル同期完了")
            } catch {
                print("⚠️ ARモデル同期失敗: \(error)")
                loadingMessage = "同期完了"
                errorMessage = "一部のARモデルを同期できませんでした"
                showError = true
            }
            
            // 同期完了後、プログレスバーが100%未満の場合は100%まで到達させる
            if ARModelManager.shared.progress < 1.0 {
                await animateProgressToComplete()
            }
            
            // 最低表示時間を確保
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed < minLoadingTime {
                try? await Task.sleep(nanoseconds: UInt64((minLoadingTime - elapsed) * 1_000_000_000))
            }
            
            // ローディング終了
            withAnimation(.easeInOut(duration: 0.5)) {
                self.isLoading = false
            }
            
        } catch {
            print("⚠️ 差分チェック失敗: \(error)")
            errorMessage = "ARモデルの確認に失敗しました"
            showError = true
            
            // エラーでもプログレスバーを100%に
            await animateProgressToComplete()
        }
    }
    
    // MARK: - リセット
    
    /// ログアウト時などに状態をリセット
    func reset() {
        isLoading = true
        loadingMessage = "読み込み中..."
        showError = false
        errorMessage = nil
        ARModelManager.shared.progress = 0.0  // ✅ プログレスもリセット
        print("🔄 AppLoaderViewModel リセット完了")
    }
}
