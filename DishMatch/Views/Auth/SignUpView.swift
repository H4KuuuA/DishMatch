//
//  SignUpView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI
import PhotosUI

/// メール/パスワードで新規登録する画面。ユーザー名・アイコンもここで設定し、
/// 登録直後にプロフィール（公開プロフィール含む）へ反映する。
struct SignUpView: View {
    @EnvironmentObject private var authService: AuthService
    let onSwitchToLogin: () -> Void

    @State private var nickname = ""
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirm = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    /// 選択・リサイズ済みのアイコン画像（未選択なら nil）
    @State private var avatarData: Data?
    @State private var isLoading = false
    @State private var error: AppError?
    @FocusState private var focusedField: Field?

    private enum Field { case nickname, email, password, passwordConfirm }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == passwordConfirm
    }

    private var isFormValid: Bool {
        !trimmedNickname.isEmpty && email.contains("@") && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        VStack(spacing: 20) {
            avatarPicker

            AuthTextField(
                systemImage: "person.fill",
                placeholder: "ユーザー名",
                text: $nickname,
                textContentType: .nickname,
                submitLabel: .next,
                onSubmit: { focusedField = .email }
            )
            .focused($focusedField, equals: .nickname)

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
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                avatarData = AvatarImageResizer.resizedJPEGData(from: data)
            }
        }
    }

    /// アイコン選択。タップで写真ライブラリから選び、選択後はプレビューを表示する。
    private var avatarPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let avatarData, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.orange.opacity(0.4))
                    }
                }
                .frame(width: 96, height: 96)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.orange.opacity(0.3), lineWidth: 2))

                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(6)
                    .background(Color.orange, in: Circle())
            }
        }
        .buttonStyle(.plain)
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
        // サインアップが成功すると認証状態リスナー→UserProfile.bind が走り、初回ドキュメント作成時に
        // ここで入力した名前・アイコンが反映される。競合を避けるため bind より前に事前登録しておく。
        UserProfile.shared.stageRegistration(nickname: trimmedNickname, avatarImageData: avatarData)
        Task {
            do {
                try await authService.signUp(email: trimmedEmail, password: password)
                // 成功時は AuthService の状態リスナーが画面を切り替える
            } catch {
                UserProfile.shared.clearStagedRegistration()
                self.error = error as? AppError ?? AppError.fromAuth(error, fallbackTitle: "新規登録に失敗しました")
            }
            isLoading = false
        }
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedNickname: String {
        nickname.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#Preview {
    SignUpView(onSwitchToLogin: {})
        .environmentObject(AuthService())
        .padding()
}
