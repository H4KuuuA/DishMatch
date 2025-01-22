//
//  CardService.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

struct CardService {
    /// カードデータを非同期で取得する関数
    func fetchCardModels() async throws -> [CardModel] {
        let stores = MockData.stores
        return stores.map({ CardModel(store: $0) })
    }
}
