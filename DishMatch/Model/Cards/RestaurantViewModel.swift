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
    private let settings = DiscoverySettings.shared // シングルトンを利用

    func fetchRestaurants(keyword: String? = nil, genre: String? = nil) {
        isLoading = true
        Task {
            do {
                // 位置情報を取得
                let locationManager = LocationManager.shared
                await locationManager.requestLocationPermissionIfNeeded() // 位置情報が取得されるまで待機

                // シングルトンから選択された range の範囲値を取得
                let range = settings.selectedRange.rangeValue

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

