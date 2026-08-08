//
//  GenreDataModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import Foundation

/// ホットペッパーグルメ ジャンルマスタAPIのレスポンス
struct GenreMasterDataModel: Decodable {
    let results: GenreResults
}

struct GenreResults: Decodable {
    let genre: [GenreOption]
}

/// 選択可能なジャンル1件（例: code "G001", name "居酒屋"）
struct GenreOption: Decodable, Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}
