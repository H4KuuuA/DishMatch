//
//  SignUpView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// メール/パスワードで新規登録する画面。
struct SignUpView: View {
    @EnvironmentObject private var authService: AuthService
    let onSwitchToLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var isLoading = false
    @State private var error: AppError?
    @FocusState private var focusedField: Field?

    private enum Field { case email, password, passwordConfirm }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == passwordConfirm
    }

    private var isFormValid: Bool {
        email.contains("@") && password.count >= 6 && passwordsMatch
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
                placeholder: "パスワード（6文字以上）",
                text: $password,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .next,
                onSubmit: { focusedField = .passwordConfirm }
            )
            .focused($focusedField, equals: .password)

            AuthTextField(
                systemImage: "lock.rotation",
                placeholder: "パスワード（確認）",
                text: $passwordConfirm,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .go,
                onSubmit: signUp
            )
            .focused($focusedField, equals: .passwordConfirm)

            if !passwordConfirm.isEmpty && !passwordsMatch {
                Text("パスワードが一致しません")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthPrimaryButton(title: "新規登録", isLoading: isLoading, isEnabled: isFormValid, action: signUp)
                .padding(.top, 4)

            switchPrompt
        }
        .alert(item: $error) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    private var switchPrompt: some View {
        HStack(spacing: 4) {
            Text("すでにアカウントをお持ちの方は")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button("ログイン", action: onSwitchToLogin)
                .font(.footnote.bold())
                .foregroundStyle(.orange)
        }
        .padding(.top, 8)
    }

    private func signUp() {
        guard isFormValid, !isLoading else { return }
        focusedField = nil
        isLoading = true
        Task {
            do {
                try await authService.signUp(email: trimmedEmail, password: password)
                // 成功時は AuthService の状態リスナーが画面を切り替える
            } catch {
                self.error = error as? AppError ?? AppError.fromAuth(error, fallbackTitle: "新規登録に失敗しました")
            }
            isLoading = false
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    SignUpView(onSwitchToLogin: {})
        .environmentObject(AuthService())
        .padding()
}
