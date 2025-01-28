//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @ObservedObject var viewModel: CardsViewModel
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @State private var viewID = UUID() // ビュー更新用の識別子
    @State private var isShowDiscoverSettings = false
    @State private var isFirstAppearance = true
    
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
                            CardView(viewModel: viewModel,
                                     restaurantViewModel: restaurantViewModel,
                                     shop: shop)
                        }
                    }
                    
                    HStack(spacing: 32) {
                        ResetCardButtonView(viewID: $viewID)
                        SwipeActionButtonView(viewModel: viewModel)
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
                if isFirstAppearance {
                    isFirstAppearance = false
                    restaurantViewModel.fetchRestaurants() // 初回データ取得
                }
                // データ同期を非同期処理の完了後に実行
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // デバッグ用の遅延
                    viewModel.shops = restaurantViewModel.restaurants
                    print("DEBUG⭐️: Synced restaurants to viewModel.shops: \(viewModel.shops.map { $0.name })")
                }
            }
        }
    }
}

#Preview {
    // モックデータ付きのCardsViewModelを渡してプレビュー
    let mockViewModel = CardsViewModel()
    return CardStackView(viewModel: mockViewModel)
}

