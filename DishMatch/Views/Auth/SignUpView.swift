//
//  SignUpView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI
import PhotosUI

/// メール/パスワードで新規登録する画面。入力の圧迫感を避けるため2ステップに分ける。
/// ステップ1: アカウント情報（アイコン・名前・メール・パスワード）。
/// ステップ2: 好きなジャンル（初期嗜好・任意）を選んで登録を確定する。
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
    /// 新規登録時に選んだ「好きなジャンル」のコード（初期嗜好）。任意選択。
    @State private var selectedGenreCodes: Set<String> = []
    /// ジャンル一覧（マスタ）。初回のみAPIから取得してキャッシュする共有カタログ。
    @ObservedObject private var genreCatalog = GenreCatalog.shared
    /// 入力ステップ。アカウント情報 → 好きなジャンル、の順に進む。
    @State private var step: Step = .account

    private enum Field { case nickname, email, password, passwordConfirm }
    private enum Step { case account, genres }

    private var passwordsMatch: Bool {
        !password.isEmpty && password == passwordConfirm
    }

    /// アカウント情報がそろっているか（ステップ1の「次へ」の有効条件）。
    private var isAccountValid: Bool {
        !trimmedNickname.isEmpty && email.contains("@") && password.count >= 6 && passwordsMatch
    }

    var body: some View {
        Group {
            switch step {
            case .account:
                accountStep
                    .transition(.move(edge: .leading).combined(with: .opacity))
            case .genres:
                genresStep
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .alert(item: $error) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
        .onAppear { genreCatalog.loadIfNeeded() }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                avatarData = AvatarImageResizer.resizedJPEGData(from: data)
            }
        }
    }

    // MARK: - ステップ1：アカウント情報

    private var accountStep: some View {
        VStack(spacing: 20) {
            avatarPicker

            AuthTextField(
                systemImage: "person.fill",
                placeholder: "ユーザー名",
                text: $nickname,
                textContentType: .nickname,
                submitLabel: .next,
                onSubmit: { focusedField = .email },
                focus: $focusedField,
                focusValue: .nickname
            )

            AuthTextField(
                systemImage: "envelope.fill",
                placeholder: "メールアドレス",
                text: $email,
                keyboardType: .emailAddress,
                textContentType: .username,
                submitLabel: .next,
                onSubmit: { focusedField = .password },
                focus: $focusedField,
                focusValue: .email
            )

            AuthTextField(
                systemImage: "lock.fill",
                placeholder: "パスワード（6文字以上）",
                text: $password,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .next,
                onSubmit: { focusedField = .passwordConfirm },
                focus: $focusedField,
                focusValue: .password
            )

            AuthTextField(
                systemImage: "lock.rotation",
                placeholder: "パスワード（確認）",
                text: $passwordConfirm,
                isSecure: true,
                textContentType: .newPassword,
                submitLabel: .next,
                onSubmit: goToGenres,
                focus: $focusedField,
                focusValue: .passwordConfirm
            )

            if !passwordConfirm.isEmpty && !passwordsMatch {
                Text("パスワードが一致しません")
                    .font(.footnote)
                    .foregroundStyle(.red.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            AuthPrimaryButton(title: "次へ", isLoading: false, isEnabled: isAccountValid, action: goToGenres)
                .padding(.top, 4)

            switchPrompt
        }
    }

    // MARK: - ステップ2：好きなジャンル

    private var genresStep: some View {
        VStack(spacing: 20) {
            // 戻る（アカウント情報へ）
            HStack {
                Button {
                    focusedField = nil
                    withAnimation { step = .account }
                } label: {
                    Label("戻る", systemImage: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
                Spacer()
            }

            VStack(spacing: 6) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                Text("好きなジャンルを選ぼう")
                    .font(.title3.bold())
                    .foregroundStyle(Color("FC"))
                Text("選んでおくと、最初のおすすめがあなた好みに。\nあとでいつでも変えられます。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            genreChips

            AuthPrimaryButton(title: "登録する", isLoading: isLoading, isEnabled: true, action: signUp)
                .padding(.top, 4)

            Button("スキップして登録", action: signUp)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    /// ジャンルのトグルチップ一覧（読み込み中はスピナー）。
    private var genreChips: some View {
        Group {
            if genreCatalog.genres.isEmpty && genreCatalog.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(genreCatalog.genres) { genre in
                        genreChip(genre)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// ジャンル1つ分のトグルチップ。
    private func genreChip(_ genre: GenreOption) -> some View {
        let isSelected = selectedGenreCodes.contains(genre.code)
        return Button {
            if isSelected {
                selectedGenreCodes.remove(genre.code)
            } else {
                selectedGenreCodes.insert(genre.code)
            }
        } label: {
            Text(genre.name)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color("FC"))
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
                .background(isSelected ? Color.orange : Color("FC").opacity(0.06), in: Capsule())
                .overlay(Capsule().stroke(Color.orange.opacity(isSelected ? 0 : 0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
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

    // MARK: - アクション

    /// ステップ1 → ステップ2（好きなジャンル）へ進む。
    private func goToGenres() {
        guard isAccountValid else { return }
        focusedField = nil
        withAnimation { step = .genres }
    }

    private func signUp() {
        guard isAccountValid, !isLoading else { return }
        focusedField = nil
        isLoading = true
        // サインアップが成功すると認証状態リスナー→UserProfile.bind が走り、初回ドキュメント作成時に
        // ここで入力した名前・アイコン・好きなジャンルが反映される。競合を避けるため bind より前に事前登録しておく。
        UserProfile.shared.stageRegistration(nickname: trimmedNickname, avatarImageData: avatarData, preferredGenreCodes: Array(selectedGenreCodes))
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
