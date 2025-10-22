//
//  LocalNotificationListView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/14.
//

import SwiftUI
import UserNotifications

struct LocalNotificationListView: View {
    // NotificationManagerを取得
    @ObservedObject private var notificationManager = NotificationManager.shared
    
    // 削除確認アラート用
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            Group {
                if notificationManager.notifications.isEmpty {
                    // 通知がない場合
                    emptyStateView
                } else {
                    // 通知リスト
                    notificationListView
                }
            }
            .navigationTitle("通知")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !notificationManager.notifications.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                showingDeleteAllAlert = true
                            } label: {
                                Label("全て削除", systemImage: "trash")
                            }
                            
                            #if DEBUG
                            Divider()
                            
                            Button {
                                notificationManager.addSampleNotifications()
                            } label: {
                                Label("サンプル追加", systemImage: "plus.circle")
                            }
                            #endif
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("全ての通知を削除", isPresented: $showingDeleteAllAlert) {
                Button("キャンセル", role: .cancel) { }
                Button("削除", role: .destructive) {
                    withAnimation {
                        notificationManager.removeAllNotifications()
                    }
                }
            } message: {
                Text("全ての通知を削除してもよろしいですか？この操作は取り消せません。")
            }
            .onAppear {
                // ✅ 開いたタイミングではバッジのみクリアする
                clearBadge()
            }
            .onDisappear {
                // ✅ 閉じたタイミングで既読判定を実行
                notificationManager.markAllAsViewed()
            }
        }
    }
    
    // MARK: - Notification List View
    
    private var notificationListView: some View {
        ScrollView(.vertical) {
            VStack(spacing: 12) {
                ForEach(notificationManager.notifications) { notification in
                    NotificationBanner(
                        appIcon: notification.type.icon,
                        appName: notification.type.appName,
                        timeAgo: notification.timeAgoText,
                        title: notification.title,
                        message: notification.message,
                        useSystemImage: true
                    )
                    //  新着判定によって透明度を制御
                    .opacity(notificationManager.isNew(notification) ? 1.0 : 0.5)
                    .swipeActions {
                        Action(
                            symbolImage: "trash.fill",
                            tint: .white,
                            background: .red
                        ) { resetPosition in
                            withAnimation {
                                notificationManager.removeNotification(id: notification.id)
                            }
                            resetPosition.toggle()
                        }
                    }
                }
            }
            .padding(15)
        }
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("通知はありません")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("スポットに近づくと通知が届きます")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            #if DEBUG
            Button {
                notificationManager.addSampleNotifications()
            } label: {
                Label("サンプル通知を追加", systemImage: "plus.circle.fill")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Badge Management
    
    /// アプリアイコンのバッジをクリア
    private func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("⚠️ バッジのクリアに失敗: \(error.localizedDescription)")
            } else {
                print("✅ バッジをクリアしました")
            }
        }
    }
}

#Preview {
    LocalNotificationListView()
}
