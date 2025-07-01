//
//  camera.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/06/30.
//

import SwiftUI
import RealityKit
import ARKit

struct ARCameraView: View {
    @State private var arScale: Float = 1.0
    @State private var showGuide = false
    @State private var showFilter = false
    @State private var selectedMode: String = "Photo"
    @State private var capturedImage: UIImage? = nil
    @State private var savedImageURL: URL? = nil
    @State private var showPreview = false
    
    var body: some View {
        ZStack {
            ARViewContainer(scale: $arScale)
                .ignoresSafeArea()
            
            VStack {
                // 上部ボタン
                HStack {
                    Button(action: { /* 戻る処理 */ }) {
                        Image(systemName: "xmark.circle")
                            .font(.title)
                    }
                    Spacer()
                    Button(action: { /* フラッシュ切替（仮） */ }) {
                        Image(systemName: "bolt.fill")
                            .font(.title)
                    }
                    Button(action: { showGuide = true }) {
                        Image(systemName: "questionmark.circle")
                            .font(.title)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                // 右スライダー
                HStack {
                    Spacer()
                    Slider(value: $arScale, in: 0.5...2.0)
                        .rotationEffect(.degrees(-90))
                        .frame(height: 200)
                        .padding()
                }
                
                // 撮影・モード・フィルター
                HStack {
                    Picker("", selection: $selectedMode) {
                        Text("Video").tag("Video")
                        Text("Photo").tag("Photo")
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .frame(width: 160)
                    
                    Spacer()
                    
                    Button(action: {
                        takeSnapshot()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 70, height: 70)
                            .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showFilter = true
                    }) {
                        Image(systemName: "camera.filters")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .padding(.trailing, 8)
                    }
                }
                .padding(.bottom, 20)
                
                // カメラ切替（ダミー）
                HStack {
                    Spacer()
                    Button(action: { /* 切替機能はARKit非対応 */ }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.title2)
                    }
                    .padding(.bottom, 10)
                    .padding(.trailing, 20)
                }
            }
        }
        .sheet(isPresented: $showGuide) {
            Text("ARカメラの使い方ガイド").padding()
        }
        .sheet(isPresented: $showPreview) {
            if let image = capturedImage {
                VStack {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding()
                    
                    Button("カメラロールに保存") {
                        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        showPreview = false
                    }
                    .padding()
                    
                    Button("閉じる") {
                        showPreview = false
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - 撮影 & 保存
    func takeSnapshot() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return
        }
        
        ARSnapshotManager.takeSnapshot(from: rootVC.view) { image in
            if let uiImage = image {
                self.capturedImage = uiImage
                self.savedImageURL = ARSnapshotManager.saveImageToAppDirectory(image: uiImage)
                self.showPreview = true
            }
        }
    }
}

#Preview {
    ARCameraView()
}
