//
//  Friend.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// 登録した友達1人分の情報。
/// `id`は相手が共有してくれた友達コード。サーバー移行後はサーバー発行のユーザーIDへ
/// そのまま置き換えられる想定でString型にしている。
struct Friend: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var avatarEmoji: String
    /// この友達が好きなジャンルのコード（例: "G001"）の集合。
    /// 現状はローカルで代理登録するが、将来サーバーができれば「友達が実際にLikeしたお店のジャンル」に置き換わる想定
    var likedGenreCodes: Set<String>
}
