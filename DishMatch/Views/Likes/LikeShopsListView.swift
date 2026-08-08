//
//  LikeShopsListView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/27.
//

import SwiftUI

struct LikeShopsListView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @ObservedObject var searchViewModel: SearchViewModel

    @Binding var searchText: String
    @State private var refreshTrigger = false
    @State private var selectedShop: Shop?
    @State private var shopPendingDeletion: Shop?

    var displayedShops: [Shop] {
        searchText.isEmpty ? restaurantViewModel.favoriteShops : searchViewModel.searchResults
    }

    var body: some View {
        NavigationView {
            Group {
                if displayedShops.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(displayedShops, id: \.id) { shop in
                            LikeShopRow(shop: shop)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedShop = shop
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        shopPendingDeletion = shop
                                    } label: {
                                        Label("削除", systemImage: "trash")
                                    }
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color("WB"))
                        }
                        // カスタムタブバーの裏に最後の行が隠れないよう、余白用の空行を足す
                        Color.clear
                            .frame(height: SizeConstants.customTabBarHeight)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.easeOut(duration: 0.5)) {
                                refreshTrigger.toggle()
                            }
                        }
                    }
                }
            }
            .background(Color("WB"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .id(refreshTrigger)
        .fullScreenCover(item: $selectedShop) { shop in
            StoreProfileView(shop: shop)
        }
        .alert(
            "お気に入りから削除しますか？",
            isPresented: Binding(
                get: { shopPendingDeletion != nil },
                set: { isPresented in if !isPresented { shopPendingDeletion = nil } }
            )
        ) {
            Button("削除", role: .destructive) {
                if let shop = shopPendingDeletion {
                    restaurantViewModel.removeFromFavorites(shop)
                }
                shopPendingDeletion = nil
            }
            Button("キャンセル", role: .cancel) {
                shopPendingDeletion = nil
            }
        } message: {
            if let shop = shopPendingDeletion {
                Text("「\(shop.name)」をお気に入りから削除します。")
            }
        }
    }

    /// 友達一覧の空状態デザインに揃え、アイコン・見出し・説明文で構成する
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "heart.slash")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("該当するお店がありません")
                .font(.headline)
            Text("ホームでお店をLikeすると、ここに並びます。")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 店舗情報を表示するRow
private extension LikeShopsListView {
    private struct LikeShopRow: View {
        let shop: Shop
        @State private var isVisible = false
        @StateObject private var imageLoader = ImageLoader()

        var body: some View {
            HStack(alignment: .top, spacing: 16) {
                if let uiImage = imageLoader.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                        .clipped()
                        .opacity(isVisible ? 1 : 0)
                        .animation(.easeIn(duration: 0.5), value: isVisible)
                } else {
                    ProgressView()
                        .frame(width: 80, height: 80)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(8)
                        .onAppear {
                            imageLoader.loadImage(from: shop.photo.pc.l)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(shop.name)
                        .font(.headline)
                        .lineLimit(1)

                    HStack {
                        Image(systemName: "fork.knife")
                        Text("\(shop.genre.name)")
                        Text("|")
                        Image(systemName: "mappin.and.ellipse")
                        Text("\(shop.stationName)")
                    }
                    .font(.caption)
                    .foregroundStyle(Color("FC").opacity(0.8))
                    .lineLimit(1)
                }
                Spacer()
            }
            .background(Color("WB"))
            .cornerRadius(8)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation {
                        isVisible = true
                    }
                }
            }
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel(friendsViewModel: FriendsViewModel())
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)

    restaurantViewModel.favoriteShops = [
        MockShop.mockShop,
        MockShop.mockShop
    ]

    return LikeShopsListView(restaurantViewModel: restaurantViewModel, searchViewModel: searchViewModel, searchText: .constant(""))
}
