//
//  InitialLoginView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import SwiftUI

struct InitialLoginView: View {
    @Binding var hasCompletedInitialSetup: Bool
    @StateObject private var viewModel = InitialLoginViewModel()
    
    @State private var showAgePicker = false
    @State private var showGenderPicker = false
    @State private var showPrefecturePicker = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case age, gender, prefecture
    }
    
    // すべてのフィールドが入力されているか
    var isFormValid: Bool {
        return viewModel.selectedAge != 0 &&
               !viewModel.selectedGender.isEmpty &&
               !viewModel.selectedPrefecture.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    // ヘッダー画像
                    Image("Splash")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 180)
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        .offset(x: 15)
                    
                    // フォーム
                    VStack(spacing: 20) {
                        // 年齢選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("年齢")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                hideAllPickers()
                                showAgePicker = true
                                focusedField = .age
                            }) {
                                HStack {
                                    Text(viewModel.selectedAge == 0 ? "" : "\(viewModel.selectedAge)")
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // 性別選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("性別")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                hideAllPickers()
                                showGenderPicker = true
                                focusedField = .gender
                            }) {
                                HStack {
                                    Text(viewModel.selectedGender.isEmpty ? "" : viewModel.selectedGender)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                        
                        // 都道府県選択
                        VStack(alignment: .leading, spacing: 8) {
                            Text("都道府県")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                hideAllPickers()
                                showPrefecturePicker = true
                                focusedField = .prefecture
                            }) {
                                HStack {
                                    Text(viewModel.selectedPrefecture.isEmpty ? "" : viewModel.selectedPrefecture)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .padding(.horizontal, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // エラーメッセージ
                    if let errorMessage = viewModel.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                    }
                    
                    // 登録ボタン
                    Button(action: {
                        hideAllPickers()
                        viewModel.saveUserProfile { success in
                            if success {
                                hasCompletedInitialSetup = true
                            }
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("登録")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color("DarkBlue") : Color.gray.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(28)
                    }
                    .disabled(viewModel.isLoading || !isFormValid)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                }
                
                // 画面の他の場所をタップしたらピッカーを閉じる
                if showAgePicker || showGenderPicker || showPrefecturePicker {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            hideAllPickers()
                        }
                }
                
                // ピッカー表示エリア（画面下部固定・最前面）
                VStack {
                    Spacer()
                    
                    if showAgePicker || showGenderPicker || showPrefecturePicker {
                        VStack(spacing: 0) {
                            // ツールバー
                            HStack {
                                Spacer()
                                Button("完了") {
                                    hideAllPickers()
                                }
                                .foregroundColor(Color("DarkBlue"))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                            .background(Color(.systemGray6))
                            
                            // ピッカー
                            if showAgePicker {
                                Picker("", selection: $viewModel.selectedAge) {
                                    ForEach(viewModel.ages, id: \.self) { age in
                                        Text(age == 0 ? "" : "\(age)").tag(age)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 216)
                                .background(Color(.systemBackground))
                            } else if showGenderPicker {
                                Picker("", selection: $viewModel.selectedGender) {
                                    ForEach(viewModel.genders, id: \.self) { gender in
                                        Text(gender).tag(gender)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 216)
                                .background(Color(.systemBackground))
                            } else if showPrefecturePicker {
                                Picker("", selection: $viewModel.selectedPrefecture) {
                                    ForEach(viewModel.prefectures, id: \.self) { prefecture in
                                        Text(prefecture).tag(prefecture)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(height: 216)
                                .background(Color(.systemBackground))
                            }
                        }
                        .transition(.move(edge: .bottom))
                    }
                }
                .ignoresSafeArea(.keyboard)
                .zIndex(1000) // 最前面に表示
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.light) // ライトモード固定
            .animation(.easeInOut(duration: 0.3), value: showAgePicker)
            .animation(.easeInOut(duration: 0.3), value: showGenderPicker)
            .animation(.easeInOut(duration: 0.3), value: showPrefecturePicker)
        }
    }
    
    private func hideAllPickers() {
        showAgePicker = false
        showGenderPicker = false
        showPrefecturePicker = false
        focusedField = nil
    }
}

#Preview {
    InitialLoginView(hasCompletedInitialSetup: .constant(false))
}
