//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @StateObject var viewModel = CardsViewModel() // `CardService` の依存を削除
    
    @State private var isShowDiscoverSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ZStack {
                    ForEach(viewModel.shops) { shop in
                        CardView(viewModel: viewModel, shop: shop) 
                    }
                }
                
                // カードがなくなった時にボタンの位置が変わるのを防ぐ
                if !viewModel.shops.isEmpty { // `cardModels` を `shops` に変更
                    HStack(spacing: 32) {
                        BackCardButtonView(viewModel: viewModel)
                        SwipeActionButtonView(viewModel: viewModel)
                        DiscoverSettingsButtonView(isShowDiscoverSettings: $isShowDiscoverSettings)
                    }
                }
            }.onAppear {
                Task {
                    await viewModel.fetchRestaurants() // データを非同期で取得
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
