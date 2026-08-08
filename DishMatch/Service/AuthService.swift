//
//  AuthService.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseAuth

/// 認証状態。ルート（ContentView）はこの状態を見てスプラッシュ/認証画面/メイン画面を出し分ける。
enum AuthState: Equatable {
    /// 起動直後、Firebase が前回のログイン状態を復元し終えるまでの状態
    case loading
    case signedOut
    case signedIn(uid: String)

    var uid: String? {
        if case let .signedIn(uid) = self { return uid }
        return nil
    }
}

/// メール/パスワード認証を扱うサービス。FirebaseAuth の状態変化を監視し、
/// アプリ全体へ `AuthState` を配信する。エラーは既存の `AppError` へ日本語で変換する。
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var authState: AuthState = .loading

    init() {
        // 前回のセッションが復元されるとリスナーが即座に呼ばれる。
        // 復元されない場合も一度 signedOut で呼ばれるため .loading から必ず遷移する。
        // AuthService はアプリ生存期間中ずっと存在するため、リスナーの解除は不要。
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.authState = .signedIn(uid: user.uid)
                } else {
                    self.authState = .signedOut
                }
            }
        }
    }

    /// メール/パスワードで新規登録する。成功すると状態リスナー経由で signedIn へ遷移する。
    func signUp(email: String, password: String) async throws {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
        } catch {
            throw AppError.fromAuth(error, fallbackTitle: "新規登録に失敗しました")
        }
    }

    /// メール/パスワードでログインする。成功すると状態リスナー経由で signedIn へ遷移する。
    func signIn(email: String, password: String) async throws {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            throw AppError.fromAuth(error, fallbackTitle: "ログインに失敗しました")
        }
    }

    /// パスワード再設定メールを送信する。
    func sendPasswordReset(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AppError.fromAuth(error, fallbackTitle: "メールを送信できませんでした")
        }
    }

    /// ログアウトする。状態リスナー経由で signedOut へ遷移する。
    func signOut() throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AppError.fromAuth(error, fallbackTitle: "ログアウトに失敗しました")
        }
    }
}
