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

    var displayedShops: [Shop] {
        searchText.isEmpty ? restaurantViewModel.favoriteShops : searchViewModel.searchResults
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if displayedShops.isEmpty {
                    Text("該当するお店がありません")
                        .foregroundColor(.gray)
                        .font(.headline)
                        .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(displayedShops, id: \.id) { shop in
                            HStack(alignment: .top, spacing: 16) {
                                LikeShopRow(shop: shop)
                            }
                        }
                    }

                    .padding()
                }
            }
            .background(Color("WB"))
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        refreshTrigger.toggle()
                    }
                }
            }
        }
        .id(refreshTrigger)
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
            .buttonStyle(PlainButtonStyle())
            .contentShape(Rectangle())
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
    let restaurantViewModel = RestaurantViewModel()
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)
    
    restaurantViewModel.favoriteShops = [
        MockShop.mockShop,
        MockShop.mockShop
    ]
    
    return LikeShopsListView(restaurantViewModel: restaurantViewModel, searchViewModel: searchViewModel, searchText: .constant(""))
}
