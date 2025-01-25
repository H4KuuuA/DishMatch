//
//  RestaurantListTestView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import SwiftUI

struct RestaurantListTestView: View {
    @StateObject private var viewModel = RestaurantViewModel()
    
    @State private var restaurants: [Shop] = []
    @State private var isLoading = true
    

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
                viewModel.fetchRestaurants() // データを取得
            }
        }
    }
}

#Preview {
    RestaurantListTestView()
}
