//
//  LikesViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import Combine
import SwiftUICore

class LikesTabViewModel: ObservableObject {
    @Published var uniqueShops: [Shop] = []

    @ObservedObject var restaurantViewModel: RestaurantViewModel
    private var cancellables = Set<AnyCancellable>()

    init(restaurantViewModel: RestaurantViewModel) {
        self.restaurantViewModel = restaurantViewModel
        bindFavoriteShops()
    }

    /// RestaurantViewModelのfavoriteShopsを監視し、変更時にuniqueShopsを更新
    private func bindFavoriteShops() {
        restaurantViewModel.$favoriteShops
        // UIスレッドで処理
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateUniqueShops()
            }
            .store(in: &cancellables)
    }

    /// 各ジャンルごとに1つだけShopをuniqueShopsに格納する。
    private func updateUniqueShops() {
        let favoriteShops = restaurantViewModel.favoriteShops
        // 文字列（ジャンル名）で管理
        var seenGenres = Set<String>()
        uniqueShops = favoriteShops.filter { shop in
            if seenGenres.contains(shop.genre.name) {
                return false
            } else {
                // 初めて見つかったジャンルなら記録し、リストに残す
                seenGenres.insert(shop.genre.name)
                return true
            }
        }
    }


}


