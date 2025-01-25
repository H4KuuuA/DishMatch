//
//  RestaurantListTestView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import SwiftUI

struct RestaurantListTestView: View {
    @StateObject private var viewModel = RestaurantViewModel()

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("データを取得中...") // ローディング表示
                        .padding()
                } else if viewModel.restaurants.isEmpty {
                    Text("データが見つかりませんでした。")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    List(viewModel.restaurants) { restaurant in
                        RestaurantRowView(restaurant: restaurant)
                    }
                }
            }
            .onAppear {
                viewModel.fetchRestaurants() // データを取得
            }
        }
    }
}

#Preview {
    RestaurantListTestView()
}
