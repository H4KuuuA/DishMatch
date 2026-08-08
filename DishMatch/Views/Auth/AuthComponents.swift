//
//  AuthComponents.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// 認証画面で使う共通の入力フィールド。アイコン付きのカプセル型デザイン。
struct AuthTextField: View {
    let systemImage: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var submitLabel: SubmitLabel = .next
    var onSubmit: () -> Void = {}

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.orange)
                .frame(width: 20)

            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .keyboardType(keyboardType)
            .textContentType(textContentType)
            .submitLabel(submitLabel)
            .onSubmit(onSubmit)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 18)
        .background(Color("FC").opacity(0.06), in: Capsule())
        .overlay(Capsule().stroke(Color.orange.opacity(0.15), lineWidth: 1))
    }
}

/// 認証画面のメインアクションボタン（ログイン・登録）。ローディング中はスピナーを表示する。
struct AuthPrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                Capsule().fill(isEnabled ? Color.orange : Color.gray.opacity(0.4))
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}
