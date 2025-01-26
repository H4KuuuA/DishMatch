//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var isDataFetched = false // データ取得のフラグ
    @State private var viewID = UUID() // ビュー更新用の識別子
    @State private var isShowDiscoverSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if restaurantViewModel.isLoading {
                    ProgressView("データを読み込んでいます...")
                        .font(.title2)
                        .padding()
                } else if restaurantViewModel.restaurants.isEmpty {
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
                            ResetCardButtonView(
                                viewModel: CardsViewModel(),
                                isDataFetched: $isDataFetched,
                                viewID: $viewID // UUIDを渡す
                            )
                            SwipeActionButtonView(viewModel: CardsViewModel())
                            DiscoverSettingsButtonView(isShowDiscoverSettings: $isShowDiscoverSettings)
                        }
                    }
                }
            }
            .id(viewID) // `viewID` を利用してビューをリロード
            .onAppear {
                if !isDataFetched {
                    restaurantViewModel.fetchRestaurants() // データ取得
                    isDataFetched = true // フラグを更新
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


