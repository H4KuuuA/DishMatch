//
//  Friend.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// 登録した友達1人分の情報。
/// `id`は相手のユーザーID（uid）。友達申請の承認時に相手の公開プロフィールから複製して保存する。
struct Friend: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    /// 相手のアイコン絵文字（画像未設定時のフォールバック）。
    var avatarEmoji: String = "🙂"
    /// 相手のアイコン画像（公開プロフィールの base64）。設定されていれば絵文字より優先して表示する。
    var avatarBase64: String? = nil
    /// この友達が好きなジャンルのコード（例: "G001"）の集合。相手の公開プロフィールから同期される。
    /// 一覧の「好きなジャンル N件」表示に使う。
    var likedGenreCodes: Set<String>
    /// この友達がLikeしたお店のID集合。相手の公開プロフィールから同期される。
    /// マッチ判定（同じお店をLikeしたか）に使う。
    var likedShopIDs: Set<String> = []

    /// base64 のアイコン画像をデコードして返す（未設定・不正なら nil）。
    var avatarImageData: Data? {
        guard let avatarBase64 else { return nil }
        return Data(base64Encoded: avatarBase64)
    }
}
