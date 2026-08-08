//
//  AuthView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// 未ログイン時に表示する認証画面のコンテナ。ログインと新規登録を切り替える。
struct AuthView: View {
    @State private var mode: AuthMode = .login

    enum AuthMode {
        case login
        case signUp
    }

    var body: some View {
        ZStack {
            Color("WB").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    header

                    switch mode {
                    case .login:
                        LoginView(onSwitchToSignUp: { withAnimation { mode = .signUp } })
                    case .signUp:
                        SignUpView(onSwitchToLogin: { withAnimation { mode = .login } })
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var header: some View {
        VStack(spacing: 8) {
            (Text("Dish").foregroundStyle(.orange) + Text("Match").foregroundStyle(.primary))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("お気に入りのお店と出会おう")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    AuthView()
}
