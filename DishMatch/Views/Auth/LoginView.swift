//
//  LoginView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// メール/パスワードでログインする画面。
struct LoginView: View {
    @EnvironmentObject private var authService: AuthService
    let onSwitchToSignUp: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: AppError?
    /// パスワード再設定メール送信の完了メッセージ
    @State private var infoMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    private var isFormValid: Bool {
        email.contains("@") && password.count >= 6
    }

    var body: some View {
        VStack(spacing: 20) {
            AuthTextField(
                systemImage: "envelope.fill",
                placeholder: "メールアドレス",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .username,
                submitLabel: .next,
                onSubmit: { focusedField = .password }
            )
            .focused($focusedField, equals: .email)

            AuthTextField(
                systemImage: "lock.fill",
                placeholder: "パスワード",
                text: $password,
                isSecure: true,
                textContentType: .password,
                submitLabel: .go,
                onSubmit: login
            )
            .focused($focusedField, equals: .password)

            HStack {
                Spacer()
                Button("パスワードを忘れた方") { resetPassword() }
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }

            AuthPrimaryButton(title: "ログイン", isLoading: isLoading, isEnabled: isFormValid, action: login)
                .padding(.top, 4)

            switchPrompt
        }
        .alert("お知らせ", isPresented: .constant(infoMessage != nil), presenting: infoMessage) { _ in
            Button("OK") { infoMessage = nil }
        } message: { message in
            Text(message)
        }
        .alert(item: $error) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    private var switchPrompt: some View {
        HStack(spacing: 4) {
            Text("アカウントをお持ちでない方は")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("新規登録", action: onSwitchToSignUp)
                .font(.footnote.bold())
                .foregroundStyle(.orange)
        }
        .padding(.top, 8)
    }

    private func login() {
        guard isFormValid, !isLoading else { return }
        focusedField = nil
        isLoading = true
        Task {
            do {
                try await authService.signIn(email: trimmedEmail, password: password)
                // 成功時は AuthService の状態リスナーが画面を切り替えるため、ここでは何もしない
            } catch {
                self.error = error as? AppError ?? AppError.fromAuth(error, fallbackTitle: "ログインに失敗しました")
            }
            isLoading = false
        }
    }

    private func resetPassword() {
        guard email.contains("@") else {
            error = AppError(title: "メールアドレスを入力してください", message: "登録済みのメールアドレスを入力してから、もう一度お試しください。")
            return
        }
        Task {
            do {
                try await authService.sendPasswordReset(email: trimmedEmail)
                infoMessage = "パスワード再設定メールを送信しました。メールをご確認ください。"
            } catch {
                self.error = error as? AppError ?? AppError.fromAuth(error, fallbackTitle: "メールを送信できませんでした")
            }
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    LoginView(onSwitchToSignUp: {})
        .environmentObject(AuthService())
        .padding()
}
