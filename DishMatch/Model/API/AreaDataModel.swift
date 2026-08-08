//
//  AreaDataModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// ホットペッパー サービスエリアマスタAPIのレスポンス。
/// サービスエリアは都道府県相当の単位で、現在地の代わりにエリア指定で検索する際に使う。
struct ServiceAreaMasterDataModel: Decodable {
    let results: ServiceAreaResults
}

struct ServiceAreaResults: Decodable {
    let serviceArea: [ServiceAreaOption]

    enum CodingKeys: String, CodingKey {
        case serviceArea = "service_area"
    }
}

/// 選択可能なサービスエリア1件（例: code "SA11", name "東京"）
struct ServiceAreaOption: Decodable, Identifiable, Hashable {
    let code: String
    let name: String

    var id: String { code }
}
