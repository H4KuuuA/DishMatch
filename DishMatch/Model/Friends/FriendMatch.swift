//
//  FriendMatch.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// 自分がLikeしたお店が、登録済み友達の好みと一致した「マッチ」の成立情報。
/// `Identifiable`にしているのは`fullScreenCover(item:)`にそのまま渡すため。
struct FriendMatch: Identifiable {
    let shop: Shop
    let friends: [Friend]

    var id: String { shop.id }
}
