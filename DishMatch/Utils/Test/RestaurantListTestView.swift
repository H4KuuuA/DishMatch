//
//  RestaurantListTestView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import SwiftUI

struct RestaurantListTestView: View {
    @State private var restaurants: [Shop] = [] // APIから取得したデータを保持
    @State private var isLoading = true         // ローディング状態を管理

    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("データを取得中...") // ローディング表示
                        .padding()
                } else if restaurants.isEmpty {
                    Text("データが見つかりませんでした。")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(restaurants) { restaurant in
                        RestaurantRowView(restaurant: restaurant)
                    }
                }
            }
            .navigationTitle("レストラン一覧")
            .onAppear {
                fetchRestaurants() // データを取得
            }
        }
    }

    // APIデータを取得する関数
    private func fetchRestaurants() {
        let apiClient = APIClient()
        Task {
            do {
                let result = try await apiClient.fetchRestaurantData(keyword: nil, range: "5", genre: nil) // 検索範囲を広げる
                DispatchQueue.main.async {
                    self.restaurants = result.results.shop
                    self.isLoading = false
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

#Preview {
    RestaurantListTestView()
}
