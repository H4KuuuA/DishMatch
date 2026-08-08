//
//  AppError.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseAuth

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
        return AppError(title: fallbackTitle, message: "通信環境を確認して、もう一度お試しください。")
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
