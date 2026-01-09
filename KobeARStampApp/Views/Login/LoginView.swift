//
//  LoginView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/16.
//

//
//  LoginView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    // 入力項目
    @State private var email = ""
    @State private var password = ""
    
    // フォーカス管理
    @FocusState private var focusedField: Field?
    enum Field {
        case email, password
    }
    
    // バリデーション（入力があるか、形式が正しいか）
    var isFormValid: Bool {
        return !email.isEmpty &&
               !password.isEmpty &&
               isValidEmail(email)
    }
    
    var body: some View {
        // NavigationStackを使用（iOS16以降推奨）ですが、
        // コピー元のNavigationViewに合わせています
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: 0) {
                        // ▼ ヘッダー画像
                        Image("Splash")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 180)
                            .padding(.top, 60)
                            .padding(.bottom, 40)
                            .offset(x: 15)
                        
                        // ▼ フォームエリア
                        VStack(spacing: 20) {
                            
                            // メールアドレス入力
                            VStack(alignment: .leading, spacing: 8) {
                                Text("メールアドレス")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                TextField("", text: $email) // $viewModel.email ではなくローカルで受けてから同期、または直接ViewModelへ
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .textContentType(.emailAddress)
                                    .focused($focusedField, equals: .email)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onChange(of: email) { newValue in
                                        viewModel.email = newValue
                                    }
                            }
                            
                            // パスワード入力
                            VStack(alignment: .leading, spacing: 8) {
                                Text("パスワード")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                SecureField("", text: $password)
                                    .textContentType(.password)
                                    .focused($focusedField, equals: .password)
                                    .frame(height: 44)
                                    .padding(.horizontal, 12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(10)
                                    .onChange(of: password) { newValue in
                                        viewModel.password = newValue
                                    }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        Spacer()
                            .frame(height: 40)
                        
                        // ▼ エラーメッセージ
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.horizontal, 24)
                                .padding(.bottom, 8)
                        }
                        
                        // ▼ ログインボタン
                        Button(action: {
                            focusedField = nil
                            Task {
                                await viewModel.signIn()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("ログイン")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            // "DarkBlue" がAssetsに定義されている前提
                            .background(isFormValid ? Color("DarkBlue") : Color.gray.opacity(0.5))
                            .foregroundColor(.white)
                            .cornerRadius(28)
                        }
                        .disabled(viewModel.isLoading || !isFormValid)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 80) // 下にリンクを置くので少し詰めました
                        
                        // ▼ 新規登録画面への遷移リンク (スタイルを追加)
                        VStack(spacing: 16) {
                            Text("アカウントをお持ちでない方")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                            
                            NavigationLink {
                                // 遷移先：InitialLoginView
                                // ※hasCompletedInitialSetupが必要な場合、適切なBindingを渡してください
                                InitialLoginView(hasCompletedInitialSetup: .constant(false))
                            } label: {
                                Text("新規登録はこちら")
                                    .font(.headline)
                                    .foregroundColor(Color("DarkBlue")) // 
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 22)
                                            .stroke(Color("DarkBlue"), lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 24)
                        }
                        .padding(.bottom, 60)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarHidden(true)
            .preferredColorScheme(.light)
            .alert("エラー", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }
    
    // バリデーションロジック (InitialLoginViewから借用)
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    LoginView()
}
