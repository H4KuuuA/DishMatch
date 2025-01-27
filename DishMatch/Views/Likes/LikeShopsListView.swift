//
//  LikeShopsListView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/27.
//

import SwiftUI

struct LikeShopsListView: View {
    @ObservedObject var viewModel: CardsViewModel
    
    var body: some View {
        NavigationView {
            List(viewModel.likedShops) { shop in
                HStack {
                    VStack(alignment: .leading) {
                        Text(shop.name)
                            .font(.headline)
                        Text(shop.address)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                }
            }
            .onAppear {
                print("DEBUG: View appeared with likedShops: \(viewModel.likedShops.map { $0.name })")
            }
        }
    }
}

#Preview {
    // モックデータ付きの CardsViewModel を使用してプレビュー
    let viewModel = CardsViewModel()
    viewModel.likeShop(MockShop.mockShop)
    viewModel.likeShop(MockShop.mockShop)
    
    return LikeShopsListView(viewModel: viewModel)
}
