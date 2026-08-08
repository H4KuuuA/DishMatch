//
//  LikesViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/02/01.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var searchHistory: [String] = []
    @Published var searchResults: [Shop] = []
    
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    private var cancellables = Set<AnyCancellable>()

    init(restaurantViewModel: RestaurantViewModel) {
        self.restaurantViewModel = restaurantViewModel
        bindFavoriteShops()
    }

    /// restaurantViewModel.favoriteShopsを監視し、変更時にsearchResultsを更新
    private func bindFavoriteShops() {
        restaurantViewModel.$favoriteShops
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateSearchResults()
            }
            .store(in: &cancellables)
    }

    /// favoriteShopsの中からsearchTextに部分一致するShopを検索
    func performSearch(_ text: String) {
        guard !text.isEmpty else {
            searchResults = []
            return
        }

        print("🔍 検索ワード: \(text)")
        
        searchResults = restaurantViewModel.favoriteShops.filter { shop in
            shop.name.contains(text) ||
            shop.genre.name.contains(text) ||
            shop.stationName.contains(text)
        }

        print("🎯 検索結果: \(searchResults.count) 件")
        addSearchHistory(text)
    }

    /// restaurantViewModel.favoriteShopsの変更時にsearchResultsを最新化
    private func updateSearchResults() {
        searchResults = restaurantViewModel.favoriteShops
    }

    /// 検索履歴を追加
    func addSearchHistory(_ text: String) {
        guard !text.isEmpty, !searchHistory.contains(text) else { return }
        searchHistory.insert(text, at: 0)
    }
    
    /// 検索履歴を削除
    func removeHistory(at offsets: IndexSet) {
        searchHistory.remove(atOffsets: offsets)
    }
    
    /// 検索履歴をクリア
    func clearHistory() {
        searchHistory.removeAll()
    }
}
