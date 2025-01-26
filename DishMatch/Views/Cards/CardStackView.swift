//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var isDataFetched = false // フラグでデータ取得を管理
    @State private var isShowDiscoverSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if restaurantViewModel.isLoading {
                    // ローディング中のインジケータ
                    ProgressView("データを読み込んでいます...")
                        .font(.title2)
                        .padding()
                } else if restaurantViewModel.restaurants.isEmpty {
                    // データが空の場合の表示
                    Text("表示する店舗がありません")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .padding()
                } else {
                    ZStack {
                        ForEach(restaurantViewModel.restaurants) { shop in
                            CardView(viewModel: CardsViewModel(), shop: shop)
                        }
                    }

                    if !restaurantViewModel.restaurants.isEmpty {
                        HStack(spacing: 32) {
                            BackCardButtonView(viewModel: CardsViewModel())
                            SwipeActionButtonView(viewModel: CardsViewModel())
                            DiscoverSettingsButtonView(isShowDiscoverSettings: $isShowDiscoverSettings)
                        }
                    }
                }
            }
            .onAppear {
                if !isDataFetched {
                    restaurantViewModel.fetchRestaurants() // データ取得
                    isDataFetched = true // フラグを更新して再取得を防ぐ
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Dish")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    + Text("Match")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
            .fullScreenCover(isPresented: $isShowDiscoverSettings) {
                DiscoverySettingsView()
            }
        }
    }
}

#Preview {
    CardStackView()
}


