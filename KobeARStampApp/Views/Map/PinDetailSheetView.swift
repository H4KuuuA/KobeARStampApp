//
//  PinDetailSheetView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/18.
//

import SwiftUI

struct PinDetailSheetView: View {
    let pin: CustomPin
    @Environment(\.dismiss) private var dismiss
    
    // ピンのエリア内にいるかどうかの状態（将来的に実装予定）
    @State private var isInPinArea: Bool = false
    
    var body: some View {
        ZStack {
            // メインコンテンツ
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // ヘッダー画像
                    headerImageView
                    
                    // コンテンツ
                    VStack(alignment: .leading, spacing: 24) {
                        // タイトルセクション
                        titleSection
                        
                        // 基本情報セクション
                        basicInfoSection
                        
                        // 詳細説明セクション
                        if let description = pin.description, !description.isEmpty {
                            descriptionSection(description)
                        }
                        
                        // 位置情報セクション
                        locationSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            VStack {
                HStack {
                    
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.black.opacity(0.3))
                    }
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                
                Spacer()
            }
            .padding(.top, 40)
            .padding(.horizontal, 20)
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Header Image
    private var headerImageView: some View {
        ZStack(alignment: .bottomLeading) {
            if let imageURL = pin.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 280)
                            .overlay {
                                ProgressView()
                                    .scaleEffect(1.2)
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(height: 280)
                            .clipped()
                    case .failure:
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 280)
                            .overlay {
                                VStack(spacing: 12) {
                                    Image(systemName: "photo")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("画像を読み込めませんでした")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue.opacity(0.6), .purple.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 280)
                    .overlay {
                        VStack(spacing: 16) {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text("画像なし")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
            }
            
            // カテゴリバッジ（画像上に配置）
            if let category = pin.category {
                categoryBadge(category)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)
            }
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(pin.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                if let subtitle = pin.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .lineLimit(nil)
                }
            }
            
            Spacer()
            
            // アクションボタン
            actionButton
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            if isInPinArea {
                // カメラを起動する処理（将来実装）
                launchCamera()
            } else {
                // 経路を表示する処理（将来実装）
                showRoute()
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: isInPinArea ? "camera.fill" : "location.north.line.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(isInPinArea ? "カメラ" : "経路")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(width: 56, height: 56)
            .background(
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: isInPinArea ?
                                [Color.green, Color.green.opacity(0.8)] :
                                [Color.blue, Color.blue.opacity(0.8)]
                            ),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (isInPinArea ? Color.green : Color.blue).opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isInPinArea ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isInPinArea)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.title2)
                    .foregroundColor(.blue)
                Text("基本情報")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "location",
                    title: "距離",
                    value: "約350m", // 仮の距離 - 実際の実装では計算が必要
                    iconColor: .green
                )
            }
        }
    }
    
    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "doc.text")
                    .font(.title2)
                    .foregroundColor(.orange)
                Text("詳細説明")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .lineLimit(nil)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.08))
                )
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "location.circle")
                    .font(.title2)
                    .foregroundColor(.red)
                Text("位置情報")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                InfoRow(
                    icon: "globe.asia.australia",
                    title: "緯度, 経度",
                    value: String(format: "%.6f, %.6f", pin.coordinate.latitude, pin.coordinate.longitude),
                    iconColor: .blue
                )
            }

            
            // 地図で開くボタン（オプション）
            Button(action: {
                openInMaps()
            }) {
                HStack {
                    Image(systemName: "map")
                    Text("マップで開く")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
            }
        }
    }

    
    // MARK: - Helper Views
    private func categoryBadge(_ category: String) -> some View {
        Text(category)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.blue)
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            )
    }
    
    // MARK: - Helper Functions
    private func openInMaps() {
        let url = URL(string: "http://maps.apple.com/?ll=\(pin.coordinate.latitude),\(pin.coordinate.longitude)&q=\(pin.title)")!
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: - Action Functions (将来実装予定)
    private func launchCamera() {
        // カメラを起動する処理をここに実装
        print("カメラを起動します - Pin: \(pin.title)")
        // 例: ARスタンプ機能やカメラビューを表示
    }
    
    private func showRoute() {
        // 経路を表示する処理をここに実装
        print("経路を表示します - Pin: \(pin.title)")
        // 例: マップアプリで経路を表示、またはアプリ内ナビゲーション
    }
    
    // MARK: - Demo Function (開発/テスト用)
    private func togglePinAreaStatus() {
        isInPinArea.toggle()
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 20, height: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    PinDetailSheetView(pin: mockPins[0])
}
