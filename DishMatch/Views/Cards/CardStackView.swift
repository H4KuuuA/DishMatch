//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
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

                    HStack(spacing: 32) {
                        ResetCardButtonView(viewID: $viewID)
                        SwipeActionButtonView(viewModel: CardsViewModel())
                        DiscoverSettingsButtonView(isShowDiscoverSettings: $isShowDiscoverSettings)
                    }
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
                DiscoverySettingsView(viewID: $viewID)
            }
            .id(viewID) // `viewID` を利用してビューをリロード
            .onChange(of: viewID) { _ in
                restaurantViewModel.fetchRestaurants() // データ取得をトリガー
            }
            .onAppear {
                restaurantViewModel.fetchRestaurants() // 初回データ取得
            }
        }
    }
}

#Preview {
    CardStackView()
}



