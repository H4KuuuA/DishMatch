//
//  LikesViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class LikesTabViewModel: ObservableObject {
    /// タブとして表示するジャンル名（先頭は常に「すべて」）。
    /// 全ジャンルを載せると大量にLikeした時にタブが際限なく増えてしまうため、
    /// 出現頻度が高い上位のジャンルだけに絞っている
    @Published var genreTabs: [String] = ["すべて"]
    /// タブに収まりきらないものも含めた全ジャンル名（出現頻度順）。「もっと見る」画面で使う
    @Published var allGenreNames: [String] = []

    @ObservedObject var restaurantViewModel: RestaurantViewModel
    private var cancellables = Set<AnyCancellable>()

    /// タブとして表示するジャンルの最大数（「すべて」を除く）
    static let maxTabGenreCount = 4

    init(restaurantViewModel: RestaurantViewModel) {
        self.restaurantViewModel = restaurantViewModel
        bindFavoriteShops()
    }

    /// RestaurantViewModelのfavoriteShopsを監視し、変更時にジャンルタブを更新
    private func bindFavoriteShops() {
        restaurantViewModel.$favoriteShops
        // UIスレッドで処理
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateGenreTabs()
            }
            .store(in: &cancellables)
    }

    /// Likeした店のジャンルを出現頻度順に集計し、上位だけをタブに載せる
    private func updateGenreTabs() {
        var genreCounts: [String: Int] = [:]
        var firstSeenOrder: [String] = []
        for shop in restaurantViewModel.favoriteShops {
            let name = shop.genre.name
            if genreCounts[name] == nil {
                firstSeenOrder.append(name)
            }
            genreCounts[name, default: 0] += 1
        }

        // 出現回数の多い順、同数なら初出順で安定ソートする
        let sortedGenres = firstSeenOrder.sorted { lhs, rhs in
            let lhsCount = genreCounts[lhs] ?? 0
            let rhsCount = genreCounts[rhs] ?? 0
            if lhsCount != rhsCount { return lhsCount > rhsCount }
            return (firstSeenOrder.firstIndex(of: lhs) ?? 0) < (firstSeenOrder.firstIndex(of: rhs) ?? 0)
        }

        allGenreNames = sortedGenres
        genreTabs = ["すべて"] + sortedGenres.prefix(Self.maxTabGenreCount)
    }
}
