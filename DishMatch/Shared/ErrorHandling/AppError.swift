//
//  AppError.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// アプリ内で発生したエラーをユーザー向けの文言として表現する共通モデル。
/// ErrorQueue/ErrorBannerViewを通じて表示する。
struct AppError: Identifiable, Equatable, Error {
    let id = UUID()
    let title: String
    let message: String

    // idはインスタンスごとに一意になるため比較から除外し、内容が同じエラーは
    // 同一とみなす（ErrorQueueでの重複排除に使う）
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        lhs.title == rhs.title && lhs.message == rhs.message
    }

    /// 既存の`APIError`/`LocationError`/`DataError`が持つerrorTitle/errorMessageを流用して変換する。
    /// 該当しない場合は`fallbackTitle`とその一般的な説明文にフォールバックする
    static func from(_ error: Error, fallbackTitle: String) -> AppError {
        if let apiError = error as? APIError {
            return AppError(title: apiError.errorTitle, message: apiError.errorMessage)
        }
        if let locationError = error as? LocationError {
            return AppError(title: locationError.errorTitle, message: locationError.errorMessage)
        }
        if let dataError = error as? DataError {
            return AppError(title: dataError.errorTitle, message: dataError.errorMessage)
        }
        if let firestoreError = firestoreAppError(from: error, fallbackTitle: fallbackTitle) {
            return firestoreError
        }
        return AppError(title: fallbackTitle, message: "通信環境を確認して、もう一度お試しください。")
    }

    /// Firestore のエラーを判別して、原因に応じた文言に変換する。
    /// Firestore のエラーでなければ nil を返す（呼び出し側で汎用フォールバックに任せる）。
    private static func firestoreAppError(from error: Error, fallbackTitle: String) -> AppError? {
        let nsError = error as NSError
        guard nsError.domain == FirestoreErrorDomain,
              let code = FirestoreErrorCode.Code(rawValue: nsError.code) else {
            return nil
        }

        logFirestoreError(nsError, code: code)

        switch code {
        case .permissionDenied:
            // ルール未反映・未ログインなど。ネットワーク不良と混同しない文言にする
            return AppError(title: fallbackTitle, message: "この操作を実行する権限がありません。時間をおいて、それでも直らない場合はアプリを最新版に更新してお試しください。")
        case .unauthenticated:
            return AppError(title: fallbackTitle, message: "ログインの有効期限が切れている可能性があります。一度ログインし直してお試しください。")
        case .unavailable, .deadlineExceeded:
            return AppError(title: fallbackTitle, message: "通信環境を確認して、もう一度お試しください。")
        default:
            return AppError(title: fallbackTitle, message: "しばらく待ってから、もう一度お試しください。")
        }
    }

    /// Firestore エラーの詳細を Xcode コンソールへ出力する（原因切り分け用）。"🔴[Firestore]" で絞り込める。
    private static func logFirestoreError(_ nsError: NSError, code: FirestoreErrorCode.Code) {
        #if DEBUG
        print("""
        🔴[Firestore] エラー発生
          ├ code     : \(nsError.code) (\(code))
          ├ message  : \(nsError.localizedDescription)
          └ userInfo : \(nsError.userInfo)
        """)
        #endif
    }

    /// FirebaseAuth のエラーをユーザー向けの日本語文言へ変換する。
    /// 想定外のコードは`fallbackTitle`＋汎用メッセージにフォールバックする。
    static func fromAuth(_ error: Error, fallbackTitle: String) -> AppError {
        // 既にAppErrorならそのまま返す（多重変換を避ける）
        if let appError = error as? AppError { return appError }

        let code = AuthErrorCode(rawValue: (error as NSError).code)
        let message: String
        switch code {
        case .invalidEmail:
            message = "メールアドレスの形式が正しくありません。"
        case .emailAlreadyInUse:
            message = "このメールアドレスは既に登録されています。ログインをお試しください。"
        case .weakPassword:
            message = "パスワードは6文字以上で設定してください。"
        case .wrongPassword, .invalidCredential:
            message = "メールアドレスまたはパスワードが正しくありません。"
        case .userNotFound:
            message = "アカウントが見つかりませんでした。新規登録をお試しください。"
        case .userDisabled:
            message = "このアカウントは無効化されています。"
        case .networkError:
            message = "通信環境を確認して、もう一度お試しください。"
        case .tooManyRequests:
            message = "試行回数が多すぎます。しばらく待ってからお試しください。"
        case .operationNotAllowed:
            // メール/パスワードのサインイン方法が Firebase コンソールで無効な場合など。
            // 設定不備なので「待てば直る」類ではない。
            message = "現在この登録方法は利用できません。設定をご確認ください。"
        default:
            message = "しばらく待ってから、もう一度お試しください。"
        }
        return AppError(title: fallbackTitle, message: message)
    }
}
