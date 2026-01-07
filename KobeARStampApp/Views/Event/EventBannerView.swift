//
//  EventBannerView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2026/01/06.
//

import SwiftUI

/// イベント情報を表示するカード
struct EventBannerView: View {
    let event: Event
    var onDismiss: (() -> Void)?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                // 上部: 画像エリア（タイトルを含む）
                imageSection
                
                // 下部: 情報エリア
                infoSection
            }
            .frame(width: 340, height: 400)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.15), radius: 15, x: 0, y: 8)
            
            // 閉じるボタン（バナー外の右上）
            Button {
                onDismiss?()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.black.opacity(0.6), .white)
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .offset(y: -36)
        }
    }
    
    // MARK: - Image Section
    
    private var imageSection: some View {
        ZStack(alignment: .topLeading) {
            // 背景画像
            GeometryReader { geometry in
                if let imageURL = event.imageURL {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        case .failure, .empty:
                            Image("hatkobe_1")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        @unknown default:
                            Image("hatkobe_1")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: geometry.size.width, height: geometry.size.height)
                        }
                    }
                } else {
                    Image("hatkobe_1")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
            .clipped()
            
            // 上部グラデーション（タイトル背景）
            LinearGradient(
                colors: [.black.opacity(0.6), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 90)
            .frame(maxHeight: .infinity, alignment: .top)
            .offset(y: -8)
            
            // タイトル（上部・完全密着）
            VStack(alignment: .leading, spacing: 0) {
                Text("\(event.name) 開催中！")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .offset(y: -8)
        }
        .frame(height: 260)
    }
    
    // MARK: - Info Section
    
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 開催期間
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(event.displayPeriod)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 16)  // 上の余白を8pxに短縮
            
            // イベント詳細
            if let description = event.description {
                Text(description)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .lineSpacing(5)
                    .truncationMode(.tail)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Preview

#if DEBUG
struct EventBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Spacer()
            
            EventBannerView(event: .previewEvent) {
                print("バナーを閉じる")
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
        .background(Color.gray.opacity(0.2))
    }
}

// Preview用のEvent拡張
extension Event {
    static var previewEvent: Event {
        Event(
            id: UUID(),
            name: "神戸開港150周年記念スタンプラリー",
            description: "神戸の歴史的スポットを巡るスタンプラリー。全てのスタンプを集めると素敵な記念品がもらえます！",
            organizer: "神戸市観光局",
            imageUrl: nil,
            startTime: Date(),
            endTime: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
            status: true,
            isPublic: true,
            createdByUser: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}
#endif
