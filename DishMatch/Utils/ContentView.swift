//
//  ContentView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct ContentView: View {
    // アプリ設定画面で選んだ外観モードをアプリ全体に反映する
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    // 初回のみチュートリアルを自動表示するためのフラグ（一度見たら二度と自動表示しない）
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @EnvironmentObject private var authService: AuthService

    var body: some View {
        Group {
            switch authService.authState {
            case .loading:
                // Firebase が前回のログイン状態を復元するまでの短い待機
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color("WB").ignoresSafeArea())
            case .signedOut:
                AuthView()
            case let .signedIn(uid):
                // ログイン中のユーザーIDに紐づくデータを同期する。
                // .id(uid) でユーザーが切り替わった際にメイン画面ツリーを作り直す
                MainTabView(uid: uid)
                    .id(uid)
                    // 初回ログイン後にチュートリアルを一度だけ全画面表示する
                    .fullScreenCover(isPresented: .init(
                        get: { !hasSeenTutorial },
                        set: { showing in if !showing { hasSeenTutorial = true } }
                    )) {
                        TutorialView { hasSeenTutorial = true }
                    }
            }
        }
        .preferredColorScheme(appearanceMode.colorScheme)
        // プロフィール(UserProfile.shared)は全体で共有する単一インスタンスのため、
        // ログイン状態に応じてここで Firestore との同期を開始・停止する
        .onChange(of: authService.authState) { _, newState in
            syncUserProfile(with: newState)
        }
        .onAppear {
            syncUserProfile(with: authService.authState)
        }
    }

    private func syncUserProfile(with state: AuthState) {
        if let uid = state.uid {
            UserProfile.shared.bind(uid: uid)
        } else {
            UserProfile.shared.unbind()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
}
