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
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showBirthDatePicker = false
    @State private var showGenderPicker = false
    @State private var showPrefecturePicker = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password, confirmPassword
    }
    
    // すべてのフィールドが入力されているか
    var isFormValid: Bool {
        return !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 6 &&
        viewModel.selectedBirthDate != nil &&
        !viewModel.selectedGender.isEmpty &&
        !viewModel.selectedPrefecture.isEmpty &&
        isValidEmail(email)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
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
                            // メールアドレス
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メールアドレス")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("", text: $email)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                                    .focused($focusedField, equals: .email)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onChange(of: email) { _ in
                                        hideAllPickers()
                                    }
                                
                                if !email.isEmpty && !isValidEmail(email) {
                                    Text("正しいメールアドレスを入力してください")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // パスワード
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("", text: $password)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onChange(of: password) { _ in
                                        hideAllPickers()
                                    }
                                
                                if !password.isEmpty && password.count < 6 {
                                    Text("6文字以上で入力してください")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // パスワード確認
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード（確認）")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onChange(of: confirmPassword) { _ in
                                        hideAllPickers()
                                    }
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("パスワードが一致しません")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }
                            
                            // 生年月日選択
                            VStack(alignment: .leading, spacing: 8) {
                                Text("生年月日")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                Button(action: {
                                    focusedField = nil
                                    hideAllPickers()
                                    showBirthDatePicker = true
                                }) {
                                    HStack {
                                        if let birthDate = viewModel.selectedBirthDate {
                                            Text(formattedDate(birthDate))
                                                .foregroundColor(.black)
                                        }
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
                                    focusedField = nil
                                    hideAllPickers()
                                    showGenderPicker = true
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
                                    focusedField = nil
                                    hideAllPickers()
                                    showPrefecturePicker = true
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
                            .frame(height: 40)
                        
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
                            focusedField = nil
                            hideAllPickers()
                            
                            guard let birthDate = viewModel.selectedBirthDate,
                                  let gender = Gender.fromDisplayName(viewModel.selectedGender) else {
                                return
                            }
                            
                            let request = SignUpRequest(
                                email: email,
                                password: password,
                                birthDate: birthDate,
                                gender: gender.rawValue,
                                prefecture: viewModel.selectedPrefecture
                            )
                            
                            viewModel.signUp(request: request) { success in
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
                        .padding(.bottom, 48)
                        Text("※本アプリは神戸エリアの観光実態把握のための実証実験として提供されています。ご入力いただいた属性情報（生年月日・都道府県等）は、統計分析のみに利用され、個人を特定する目的では使用されません。")
                            .font(.caption2)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 30)
                            .padding(.bottom, 120)       
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // 画面の他の場所をタップしたらピッカーとキーボードを閉じる
                if showBirthDatePicker || showGenderPicker || showPrefecturePicker {
                    Color.black.opacity(0.001)
                        .ignoresSafeArea()
                        .onTapGesture {
                            hideAllPickers()
                        }
                }
                
                // ピッカー表示エリア（画面下部固定・最前面）
                VStack {
                    Spacer()
                    
                    if showBirthDatePicker || showGenderPicker || showPrefecturePicker {
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
                            if showBirthDatePicker {
                                DatePicker(
                                    "",
                                    selection: Binding(
                                        get: { viewModel.selectedBirthDate ?? Date() },
                                        set: { viewModel.selectedBirthDate = $0 }
                                    ),
                                    in: ...Date(),
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.wheel)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "ja_JP"))
                                .environment(\.calendar, Calendar(identifier: .gregorian))
                                .frame(maxWidth: .infinity)
                                .frame(height: 216)
                                .clipped()
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
                        .background(Color(.systemBackground))
                        .transition(.move(edge: .bottom))
                    }
                }
                .ignoresSafeArea(.keyboard)
                .zIndex(1000)
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.light)
            .animation(.easeInOut(duration: 0.3), value: showBirthDatePicker)
            .animation(.easeInOut(duration: 0.3), value: showGenderPicker)
            .animation(.easeInOut(duration: 0.3), value: showPrefecturePicker)
        }
    }
    
    private func hideAllPickers() {
        showBirthDatePicker = false
        showGenderPicker = false
        showPrefecturePicker = false
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年M月d日"
        return formatter.string(from: date)
    }
}

#Preview {
    InitialLoginView(hasCompletedInitialSetup: .constant(false))
}
