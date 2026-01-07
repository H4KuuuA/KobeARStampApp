//
//  KobeARStampAppApp.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/27.
//

import SwiftUI

@main
struct KobeARStampAppApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var stampManager = StampManager.shared
    @StateObject private var proximityNotification: ProximityNotificationCoordinator
    @State private var showSplash = true  // ✅ Splash表示フラグ
    
    init() {
        let manager = StampManager.shared
        _stampManager = StateObject(wrappedValue: manager)
        _proximityNotification = StateObject(wrappedValue: ProximityNotificationCoordinator(spots: manager.allSpots))
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // メインコンテンツ
                ContentView()
                    .environmentObject(proximityNotification)
                    .environmentObject(stampManager)
                    .opacity(showSplash ? 0 : 1)
                
                // ✅ Splash画面（起動時のみ表示）
                if showSplash {
                    SplashView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .task {
                // Splash表示時間（1.5秒）
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                
                withAnimation(.easeOut(duration: 0.5)) {
                    showSplash = false
                }
                
                #if DEBUG
                // Splash終了後にSupabaseチェック
                await performSupabaseCheck()
                #endif
            }
        }
    }
    
    // MARK: - Supabase接続チェック
    
    /// Supabase接続の動作確認(デバッグ専用)
    private func performSupabaseCheck() async {
        print("\n" + String(repeating: "=", count: 60))
        print("🔍 Supabase接続チェック開始")
        print(String(repeating: "=", count: 60))
        
        // 1. 設定ファイルの確認
        print("\n【ステップ1】Config.plist の確認...")
        if SupabaseManager.validateConfig() {
            print("✅ Config.plist OK")
        } else {
            print("❌ Config.plist が見つからないか、設定が不完全です")
            print("   → Config.plist.example をコピーして設定してください")
            return
        }
        
        // 1.5 認証状態の確認
        print("\n【ステップ1.5】現在の認証状態チェック...")
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            print("👤 ログイン状態: [ログイン済み]")
            print("   User ID : \(session.user.id)")
            print("   Email   : \(session.user.email ?? "メールアドレスなし")")
            print("   Role    : \(session.user.role ?? "user")")
        } catch {
            print("👤 ログイン状態: [未ログイン]")
            print("   詳細: セッションが見つかりません(または期限切れ)")
        }
        
        // 2. データベース接続テスト
        print("\n【ステップ2】データベース接続テスト...")
        let connected = await DataRepository.shared.testConnection()
        if connected {
            print("✅ データベース接続成功")
        } else {
            print("❌ データベース接続失敗")
            print("   → Supabase URLとAnon Keyを確認してください")
            return
        }
        
        // 3. スポット取得テスト
        print("\n【ステップ3】スポットデータ取得テスト...")
        do {
            let spots = try await DataRepository.shared.fetchActiveSpots()
            print("✅ スポット取得成功: \(spots.count)件")
            
            if spots.isEmpty {
                print("⚠️  公開中のスポットが0件です")
                print("   → Web管理画面でスポットを作成し、is_active を true に設定してください")
            } else {
                print("\n📍 取得したスポット:")
                for (index, spot) in spots.prefix(3).enumerated() {
                    print("   \(index + 1). \(spot.name)")
                    print("      住所: \(spot.address)")
                    print("      カテゴリ: \(spot.category ?? "なし")")
                }
                if spots.count > 3 {
                    print("   ... 他 \(spots.count - 3) 件")
                }
            }
        } catch {
            print("❌ スポット取得エラー: \(error.localizedDescription)")
            print("   詳細: \(error)")
        }
        
        // 4. イベント取得テスト
        print("\n【ステップ4】イベントデータ取得テスト...")
        do {
            let events = try await DataRepository.shared.fetchPublicEvents()
            print("✅ イベント取得成功: \(events.count)件")
            
            if events.isEmpty {
                print("⚠️  公開中のイベントが0件です")
            } else {
                print("\n🎉 取得したイベント:")
                for (index, event) in events.prefix(3).enumerated() {
                    print("   \(index + 1). \(event.name)")
                    if let organizer = event.organizer {
                        print("      主催: \(organizer)")
                    }
                }
                if events.count > 3 {
                    print("   ... 他 \(events.count - 3) 件")
                }
            }
        } catch {
            print("❌ イベント取得エラー: \(error.localizedDescription)")
        }
        
        // 5. 最終結果
        print("\n" + String(repeating: "=", count: 60))
        print("✅ Supabase接続チェック完了")
        print("   すべての基本機能が正常に動作しています")
        print(String(repeating: "=", count: 60) + "\n")
    }
}

// MARK: - デバッグ専用の接続テストビュー(オプション)

#if DEBUG
/// Supabase接続テスト専用画面
/// ContentViewの代わりに表示してテストできます
struct SupabaseTestView: View {
    @State private var testStatus = "テスト待機中..."
    @State private var spots: [Spot] = []
    @State private var events: [Event] = []
    @State private var isLoading = false
    @State private var showDetails = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // ステータス表示
                    VStack(spacing: 12) {
                        Image(systemName: statusIcon)
                            .font(.system(size: 60))
                            .foregroundColor(statusColor)
                        
                        Text(testStatus)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.5)
                            .padding()
                    }
                    
                    // テスト実行ボタン
                    Button {
                        Task {
                            await runTest()
                        }
                    } label: {
                        Label("接続テスト実行", systemImage: "network")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    
                    // 結果詳細
                    if !spots.isEmpty || !events.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            // スポット一覧
                            if !spots.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundColor(.red)
                                        Text("取得したスポット (\(spots.count)件)")
                                            .font(.headline)
                                    }
                                    
                                    ForEach(spots.prefix(5)) { spot in
                                        HStack {
                                            Circle()
                                                .fill(spot.pinColorValue)
                                                .frame(width: 12, height: 12)
                                            VStack(alignment: .leading) {
                                                Text(spot.name)
                                                    .font(.subheadline)
                                                Text(spot.address)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .padding()
                                .background(Color.green.opacity(0.1))
                                .cornerRadius(12)
                            }
                            
                            // イベント一覧
                            if !events.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: "calendar.badge.exclamationmark")
                                            .foregroundColor(.blue)
                                        Text("取得したイベント (\(events.count)件)")
                                            .font(.headline)
                                    }
                                    
                                    ForEach(events.prefix(5)) { event in
                                        VStack(alignment: .leading) {
                                            Text(event.name)
                                                .font(.subheadline)
                                            if let organizer = event.organizer {
                                                Text("主催: \(organizer)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.leading)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Supabase接続テスト")
        }
    }
    
    private var statusIcon: String {
        if isLoading {
            return "hourglass"
        } else if testStatus.contains("✅") {
            return "checkmark.circle.fill"
        } else if testStatus.contains("❌") {
            return "xmark.circle.fill"
        } else {
            return "questionmark.circle"
        }
    }
    
    private var statusColor: Color {
        if testStatus.contains("✅") {
            return .green
        } else if testStatus.contains("❌") {
            return .red
        } else {
            return .gray
        }
    }
    
    private func runTest() async {
        await MainActor.run {
            isLoading = true
            testStatus = "テスト実行中..."
            spots = []
            events = []
        }
        
        do {
            // 接続確認
            let connected = await DataRepository.shared.testConnection()
            guard connected else {
                await MainActor.run {
                    testStatus = "❌ データベース接続失敗\n\nConfig.plistを確認してください"
                    isLoading = false
                }
                return
            }
            
            // スポット取得
            let fetchedSpots = try await DataRepository.shared.fetchActiveSpots()
            
            // イベント取得
            let fetchedEvents = try await DataRepository.shared.fetchPublicEvents()
            
            await MainActor.run {
                self.spots = fetchedSpots
                self.events = fetchedEvents
                self.testStatus = "✅ 接続成功！\n\nスポット: \(fetchedSpots.count)件\nイベント: \(fetchedEvents.count)件"
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                testStatus = "❌ エラー発生\n\n\(error.localizedDescription)"
                isLoading = false
            }
            print("詳細エラー: \(error)")
        }
    }
}

#Preview {
    SupabaseTestView()
}
#endif
