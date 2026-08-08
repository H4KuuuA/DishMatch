//
//  VisitedShopsView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import SwiftUI

/// Likeして出会ったお店の中から、実際に「行った」ものを記録・一覧する画面。
/// 出会って終わりではなく、その後の関係を残せるようにする。
struct VisitedShopsView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @State private var selectedShop: Shop?

    var body: some View {
        NavigationStack {
            Group {
                if restaurantViewModel.favoriteShops.isEmpty {
                    emptyState
                } else {
                    List(restaurantViewModel.favoriteShops) { shop in
                        shopRow(for: shop)
                    }
                }
            }
            .navigationTitle("行ったお店")
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $selectedShop) { shop in
                StoreProfileView(shop: shop)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("まだ出会ったお店がありません")
                .font(.headline)
            Text("ホームでLikeしたお店がここに並びます。行ったお店にはチェックを付けて記録できます。")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func shopRow(for shop: Shop) -> some View {
        let isVisited = restaurantViewModel.visitedShopIDs.contains(shop.id)

        return HStack(spacing: 12) {
            Button {
                restaurantViewModel.toggleVisited(shop)
            } label: {
                Image(systemName: isVisited ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isVisited ? .orange : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(shop.name)
                    .font(.headline)
                    .strikethrough(false)
                Text(shop.genre.name)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.gray)
                .font(.caption)
        }
        .contentShape(Rectangle())
        .padding(.vertical, 4)
        .onTapGesture {
            selectedShop = shop
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel(friendsViewModel: FriendsViewModel())
    restaurantViewModel.favoriteShops = [MockShop.mockShop]
    return VisitedShopsView(restaurantViewModel: restaurantViewModel)
}
