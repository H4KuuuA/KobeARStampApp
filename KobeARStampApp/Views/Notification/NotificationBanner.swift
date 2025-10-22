//
//  NotificationBanner.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/15.
//

import SwiftUI

struct NotificationBanner: View {
    // カスタマイズ可能なプロパティ
    var appIcon: String = "bell.fill" // SF Symbolsまたは画像名
    var appName: String = "マイアプリ"
    var timeAgo: String = "今"
    var title: String = "通知タイトル"
    var message: String = "ここに通知メッセージが表示されます"
    var iconBackgroundColor: Color = .blue // アイコンの背景色
    var useSystemImage: Bool = true // SF Symbols使用時はtrue、画像使用時はfalse
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // アプリアイコン
            Group {
                if useSystemImage {
                    Image(systemName: appIcon)
                        .resizable()
                        .foregroundColor(.white)
                        .padding(6)
                } else {
                    Image(appIcon)
                        .resizable()
                }
            }
            .frame(width: 40, height: 40)
            .background(iconBackgroundColor.gradient)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // テキストコンテンツ
            VStack(alignment: .leading, spacing: 2) {
                // アプリ名と時刻
                HStack(spacing: 4) {
                    Text(appName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(timeAgo)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                // タイトル
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // メッセージ
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 13)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13)
                .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

// MARK: - NotificationItem用の便利なイニシャライザ
extension NotificationBanner {
    /// NotificationItemから直接バナーを作成
    init(notification: NotificationItem) {
        self.appIcon = notification.type.icon
        self.appName = notification.type.appName
        self.timeAgo = notification.timeAgoText
        self.title = notification.title
        self.message = notification.message
        self.iconBackgroundColor = notification.type.color
        self.useSystemImage = true
    }
}

// プレビュー用
#Preview {
    VStack(spacing: 20) {
        // NotificationItemから作成
        NotificationBanner(notification: .sampleProximity)
        
        NotificationBanner(notification: .sampleAchievement)
        
        NotificationBanner(notification: .sampleSystem)
        
        // カスタム作成
        NotificationBanner(
            appIcon: "heart.fill",
            appName: "ヘルスケア",
            timeAgo: "2時間前",
            title: "目標達成",
            message: "本日の歩数目標を達成しました！",
            iconBackgroundColor: .pink,
            useSystemImage: true
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
