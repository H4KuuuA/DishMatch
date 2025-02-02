//
//  ErrorModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

enum APIError: Error {
    /// URLが正しく生成できなかった場合に発生するエラー/
    case failCreateURL
    /// セッション中にエラーが発生した場合（ネットワーク接続の問題など）
    case sessionError
    /// APIリクエスト自体でエラーが発生した場合（サーバーエラーやタイムアウトなど）/
    case requestError(Error)
    /// APIレスポンスのデコードに失敗した場合（JSONの形式が不正など）/
    case decodeError(Error)

    var errorTitle: String {
        switch self {
        case .failCreateURL:
            "不明なエラー"
        case .sessionError:
            "通信エラー"
        case .requestError(_):
            "リクエストエラー"
        case .decodeError(_):
            "デコードエラー"
        }
    }

    var errorMessage: String {
        switch self {
        case .failCreateURL:
            "エラーが発生しました"
        case .sessionError:
            "インターネットに接続していることを確認してください"
        case .requestError:
            "リクエストに失敗しました"
        case .decodeError:
            "データの取得に失敗しました"
        }
    }

}

enum DataError: Error {
    case imageError

    var errorTitle: String {
        switch self {
        case .imageError:
            "画像取得エラー"
        }
    }

    var errorMessage: String {
        switch self {
        case .imageError:
            "画像の取得に失敗しました"
        }
    }
}

enum LocationError: Error {
    case locationServicesDisabled
    case authorizationDenied
    case failedToGetLocation

    var errorTitle: String {
        switch self {
        case .locationServicesDisabled:
            return "位置情報サービスが無効"
        case .authorizationDenied:
            return "位置情報の許可が必要"
        case .failedToGetLocation:
            return "位置情報の取得に失敗"
        }
    }

    var errorMessage: String {
        switch self {
        case .locationServicesDisabled:
            return "位置情報サービスが無効になっています。設定アプリから有効にしてください。"
        case .authorizationDenied:
            return "アプリの位置情報利用が拒否されています。設定アプリから許可してください。"
        case .failedToGetLocation:
            return "現在の位置情報を取得できませんでした。通信環境を確認してください。"
        }
    }
}
