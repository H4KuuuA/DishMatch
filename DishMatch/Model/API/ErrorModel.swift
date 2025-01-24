//
//  ErrorModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

enum APIError: Error {
    case failCreateURL
    case sessionError
    case requestError(Error)
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
