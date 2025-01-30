//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
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
                } else if restaurantViewModel.shopList.isEmpty {
                    Text("表示する店舗がありません")
                        .foregroundColor(.gray)
                        .font(.title3)
                        .padding()
                } else {
                    ZStack {
                        ForEach(Array(restaurantViewModel.shopList.enumerated()), id: \.element.id) { index, shop in
                            CardView(restaurantViewModel: restaurantViewModel, shop: shop)
                                
                                .onChange(of: restaurantViewModel.shopList) { newList in
                                    // ✅ 残り5枚以下になったら次のページを取得
                                    if newList.count <= 5 && !restaurantViewModel.isLoading {
                                        restaurantViewModel.fetchNextPage()
                                    }
                                }

                        }

                    }
                    
                    HStack(spacing: 32) {
                        ResetCardButtonView(viewID: $viewID)
                        SwipeActionButtonView(restaurantViewModel: restaurantViewModel)
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
                restaurantViewModel.fetchShops(startIndex: 1) // データ取得をトリガー
            }
            .onAppear {
                if isFirstAppearance {
                    isFirstAppearance = false
                    restaurantViewModel.fetchShops(startIndex: 1) // 初回データ取得
                }
                //                // データ同期を非同期処理の完了後に実行
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // デバッグ用の遅延
                //                    viewModel.shops = restaurantViewModel.restaurants
                //                    print("DEBUG⭐️: Synced restaurants to viewModel.shops: \(viewModel.shops.map { $0.name })")
                //                }
            }
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel()
    restaurantViewModel.shopList = [
        MockShop.mockShop,
        MockShop.mockShop
    ]
    return CardStackView(restaurantViewModel: restaurantViewModel)
}
