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
            .background(Color.blue.gradient)
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

// プレビュー用
#Preview {
    VStack(spacing: 20) {
        // 使用例1: SF Symbolsを使用
        NotificationBanner(
            appIcon: "bell.fill",
            appName: "リマインダー",
            timeAgo: "今",
            title: "タスクの期限",
            message: "プロジェクトの提出期限が近づいています",
            useSystemImage: true
        )
        
        // 使用例2: カスタム内容
        NotificationBanner(
            appIcon: "envelope.fill",
            appName: "メール",
            timeAgo: "1分前",
            title: "新着メッセージ",
            message: "山田太郎さんから新しいメッセージが届いています。内容を確認してください。",
            useSystemImage: true
        )
        
        // 使用例3: 長いメッセージ
        NotificationBanner(
            appIcon: "message.fill",
            appName: "メッセージ",
            timeAgo: "5分前",
            title: "佐藤花子",
            message: "こんにちは！明日の会議の時間が変更になりました。詳細はメールで送りますね。",
            useSystemImage: true
        )
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.gray.opacity(0.2))
}
