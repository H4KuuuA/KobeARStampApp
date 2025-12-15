//
//  UserGudieView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/12.
//

import SwiftUI

// MARK: - User Guide View
struct UserGuideView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // ヘッダー
                VStack(alignment: .center, spacing: 12) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("DarkBlue"))
                    
                    Text("アプリのチュートリアル")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("このアプリは、まち歩きをもっと楽しくするための\nARスタンプラリー風アプリです。")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Text("難しい操作はありません。はじめての方でもすぐに使えるよう、最低限だけまとめています。")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal)
                
                // ステップ一覧
                VStack(spacing: 24) {
                    GuideStepView(
                        stepNumber: 1,
                        icon: "iphone",
                        title: "アプリを開く",
                        description: "アプリを起動すると、まずカメラの使用許可を求められることがあります。案内に従って「許可」してください。AR表示に必要なためです。",
                        iconColor: (Color("DarkBlue"))
                    )
                    
                    GuideStepView(
                        stepNumber: 2,
                        icon: "location.fill",
                        title: "位置情報の許可",
                        description: "まち歩き中に現在地を確認したり、スポット付近に来たことを認識するために必要です。こちらも「アプリの使用中は許可」を選んでください。",
                        iconColor: (Color("DarkBlue"))
                    )
                    
                    GuideStepView(
                        stepNumber: 3,
                        icon: "map",
                        title: "マップを見る",
                        description: "ホーム画面には地図が表示されます。自分の位置や、スポットのおおよその場所が確認できます。",
                        iconColor: (Color("DarkBlue")),
                        detailContent: AnyView(
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 12) {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.blue)
                                    Text("青い点 → あなたの現在地")
                                        .font(.subheadline)
                                }
                                
                                HStack(spacing: 12) {
                                    Image(systemName: "mappin.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.red)
                                    Text("ピン → スポットの場所")
                                        .font(.subheadline)
                                }
                                
                                Text("好きなところへ歩いていきましょう。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        )
                    )
                    
                    GuideStepView(
                        stepNumber: 4,
                        icon: "figure.walk",
                        title: "スポットの近くに行く",
                        description: "スポットの近くに行くと、アプリが自動で反応します。画面の案内に従ってください。",
                        iconColor: (Color("DarkBlue"))
                    )
                    
                    GuideStepView(
                        stepNumber: 5,
                        icon: "camera.fill",
                        title: "ARを楽しむ",
                        description: "スポットについたら、カメラを向けてください。特別なARコンテンツが表示されます。",
                        iconColor: (Color("DarkBlue")),
                        detailContent: AnyView(
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text("近づいたり、角度を変えたりして見てみる")
                                        .font(.subheadline)
                                }
                                
                                HStack(spacing: 8) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.green)
                                    Text("写真を撮って楽しむ")
                                        .font(.subheadline)
                                }
                                
                                Text("操作はとてもシンプルです。")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 4)
                            }
                        )
                    )
                    
                    GuideStepView(
                        stepNumber: 6,
                        icon: "xmark.circle.fill",
                        title: "終わり方",
                        description: "アプリはいつでも閉じて大丈夫です。位置情報やデータは匿名で扱われ、個人が特定されることはありません。",
                        iconColor: (Color("DarkBlue"))
                    )
                }
                .padding(.horizontal)
                
                // 困ったときは
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("困ったときは")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    VStack(spacing: 12) {
                        TroubleshootingItem(
                            problem: "ARが出ない",
                            solution: "明るい場所で平面にカメラを向けてください"
                        )
                        
                        TroubleshootingItem(
                            problem: "現在地がズレる",
                            solution: "数秒待つか、屋外で試してください"
                        )
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)
                
                // フッター
                Text("それでは、楽しいまち歩きを!")
                    .font(.headline)
                    .foregroundColor(Color("DarkBlue"))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            }
            .padding(.bottom, 80)
        }
        .navigationTitle("使い方ガイド")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Guide Step View
struct GuideStepView: View {
    let stepNumber: Int
    let icon: String
    let title: String
    let description: String
    let iconColor: Color
    var detailContent: AnyView?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                // ステップ番号
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 50, height: 50)
                    
                    VStack(spacing: 2) {
                        Image(systemName: icon)
                            .font(.system(size: 18))
                            .foregroundColor(.white)
                        Text("\(stepNumber)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                }
                
                // コンテンツ
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let detailContent = detailContent {
                        detailContent
                            .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(16)
    }
}

// MARK: - Troubleshooting Item
struct TroubleshootingItem: View {
    let problem: String
    let solution: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.orange)
                Text(problem)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                Text(solution)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 22)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        UserGuideView()
    }
}
