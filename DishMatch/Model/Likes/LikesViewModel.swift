//
//  LikesViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import Combine

class LikesTabViewModel: ObservableObject {
    @Published var uniqueStores: [Store] = []

    private var stores: [Store] = [] {
        didSet {
            updateUniqueStores()
        }
    }

    init(stores: [Store]) {
        self.stores = stores
        updateUniqueStores()
    }

    // storesが変更された場合にuniqueStoresを更新
    func updateStores(_ newStores: [Store]) {
        self.stores = newStores
    }

    // 重複するジャンルを排除し、最初のStoreを取得
    private func updateUniqueStores() {
        let uniqueGenres = Array(Set(stores.map { $0.genre })) // ジャンルの重複を排除
        uniqueStores = uniqueGenres.compactMap { genre in
            // genreに一致する最初のStoreを取得
            stores.first { $0.genre == genre }
        }
    }
}
