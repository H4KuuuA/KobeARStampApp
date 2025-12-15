//
//  FAQView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/12.
//

import SwiftUI

// MARK: - FAQ View
struct FAQView: View {
    @State private var expandedItems: Set<Int> = []
    
    let faqItems: [FAQItem] = [
        FAQItem(
            id: 1,
            question: "ARが出てこないのですが?",
            answer: "明るい場所でカメラをゆっくり動かしてみてください。床や壁など、模様がある場所のほうがARが認識しやすいです。それでも出ない場合は、一度アプリを再起動すると改善することがあります。",
            icon: "camera.fill",
            iconColor: .pink
        ),
        FAQItem(
            id: 2,
            question: "現在地がずれています／正しく表示されません。",
            answer: "建物の中や地下ではGPSが不安定になることがあります。屋外に出て数秒待つと、位置が修正されることが多いです。Wi-Fiをオンにしておくと、精度が上がる場合もあります。",
            icon: "location.fill",
            iconColor: .yellow
        ),
        FAQItem(
            id: 3,
            question: "個人情報は本当に取られていませんか?",
            answer: "はい、匿名で利用できます。位置情報や操作データは個人を特定できない形に加工されて提供されます。名前や連絡先など、個人がわかる情報は取得していません。",
            icon: "lock.shield.fill",
            iconColor: .blue
        )
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // ヘッダー
                VStack(spacing: 12) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(Color("DarkBlue"))
                    
                    Text("よくある質問")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("アプリ利用時のよくある疑問にお答えします")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .padding(.horizontal)
                
                // FAQ一覧
                VStack(spacing: 16) {
                    ForEach(faqItems) { item in
                        FAQItemView(
                            item: item,
                            isExpanded: expandedItems.contains(item.id)
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedItems.contains(item.id) {
                                    expandedItems.remove(item.id)
                                } else {
                                    expandedItems.insert(item.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // フッター
                VStack(spacing: 16) {
                    Divider()
                        .padding(.vertical, 8)
                    
                    VStack(spacing: 12) {
                        Image(systemName: "envelope.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("解決しない場合は")
                            .font(.headline)
                        
                        Text("お問い合わせフォームからご連絡ください")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        NavigationLink(destination: ContactView()) {
                            HStack {
                                Image(systemName: "envelope")
                                Text("お問い合わせ")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("DarkBlue"))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    .padding(.vertical, 24)
                }
                .padding(.top, 32)
            }
            .padding(.bottom, 80)
        }
        .navigationTitle("よくある質問")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - FAQ Item Model
struct FAQItem: Identifiable {
    let id: Int
    let question: String
    let answer: String
    let icon: String
    let iconColor: Color
}

// MARK: - FAQ Item View
struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // 質問部分（タップ可能）
            Button(action: onTap) {
                HStack(spacing: 16) {
                    // アイコン
                    ZStack {
                        Circle()
                            .fill(item.iconColor.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: item.icon)
                            .font(.system(size: 20))
                            .foregroundColor(item.iconColor)
                    }
                    
                    // 質問テキスト
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Q\(item.id)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(item.iconColor)
                        
                        Text(item.question)
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    // 展開アイコン
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(0))
                }
                .padding(16)
                .background(Color.white)
            }
            .buttonStyle(PlainButtonStyle())
            
            // 回答部分（展開時のみ表示）
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    HStack(alignment: .top, spacing: 12) {
                        Text("A")
                            .font(.body)
                            .fontWeight(.bold)
                            .foregroundColor(item.iconColor)
                            .frame(width: 20)
                        
                        Text(item.answer)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .background(Color.white)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isExpanded ? item.iconColor.opacity(0.3) : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        FAQView()
    }
}
