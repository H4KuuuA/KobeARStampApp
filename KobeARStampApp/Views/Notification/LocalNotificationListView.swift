//
//  LocalNotificationListView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/14.
//

import SwiftUI

struct LocalNotificationListView: View {
    // サンプルデータ（後で実際のデータに置き換え可能）
    let sampleNotifications = [
        ("bell.fill", "リマインダー", "今", "タスクの期限", "プロジェクトの提出期限が近づいています"),
        ("envelope.fill", "メール", "1分前", "新着メッセージ", "山田太郎さんから新しいメッセージが届いています"),
        ("message.fill", "メッセージ", "5分前", "佐藤花子", "こんにちは！明日の会議の時間が変更になりました"),
        ("cart.fill", "ショッピング", "10分前", "注文完了", "ご注文が正常に処理されました"),
        ("calendar", "カレンダー", "30分前", "イベント開始", "1時間後にミーティングが始まります"),
        ("star.fill", "お気に入り", "1時間前", "新着情報", "お気に入りの店舗から新商品が入荷しました"),
        ("heart.fill", "ヘルスケア", "2時間前", "目標達成", "本日の歩数目標を達成しました！"),
        ("photo.fill", "写真", "3時間前", "思い出", "1年前の今日の写真を見てみましょう"),
        ("music.note", "ミュージック", "5時間前", "プレイリスト", "あなたへのおすすめプレイリストを更新しました"),
        ("bell.badge.fill", "通知", "昨日", "システム", "アプリのアップデートが利用可能です")
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical) {
                VStack(spacing: 12) {
                    ForEach(Array(sampleNotifications.enumerated()), id: \.offset) { index, notification in
                        NotificationBanner(
                            appIcon: notification.0,
                            appName: notification.1,
                            timeAgo: notification.2,
                            title: notification.3,
                            message: notification.4,
                            useSystemImage: true
                        )
                        .swipeActions {
                            Action(symbolImage: "trash.fill", tint: .white, background: .red) { resetPosition in
                                // 削除処理をここに記述
                                resetPosition.toggle()
                            }
                        }
                    }
                }
                .padding(15)
            }
            .navigationTitle(Text("通知"))
        }
    }
}

#Preview {
    LocalNotificationListView()
}
