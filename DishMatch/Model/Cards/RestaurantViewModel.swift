//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Shop] = []
    @Published var isLoading = false

    private let apiClient = APIClient()

    /// レストランデータを取得する関数
    func fetchRestaurants(keyword: String? = nil, range: String = "5", genre: String? = nil) {
        isLoading = true
        Task {
            do {
                // APIからデータを取得
                let result = try await apiClient.fetchRestaurantData(keyword: keyword, range: range, genre: genre)
                DispatchQueue.main.async {
                    self.restaurants = result.results.shop // データを更新
                    self.isLoading = false                // ローディング終了
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

