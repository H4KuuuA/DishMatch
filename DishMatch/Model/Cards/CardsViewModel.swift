//
//  CardsViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

@MainActor
class CardsViewModel: ObservableObject {
    @Published var shops = [Shop]() // Shopデータを直接保持
    @Published var buttonSwipeAction: SwipeAction? // スワイプアクションを保持
    @Published var likedShops: [Shop] = []
    
    private let restaurantViewModel = RestaurantViewModel()
    
    init() {
        //        Task {
        //            await fetchRestaurants() // fetchCardModelsをfetchRestaurantsに置き換え
        //        }
    }
    
    //    // `Shop` データをAPIから取得する
    //    func fetchRestaurants() async {
    //        do {
    //            await restaurantViewModel.fetchRestaurants() // APIからデータを取得
    //            self.shops = restaurantViewModel.restaurants // データを更新
    //            for shop in self.shops {
    //                        print("DEBUG: Image URL - \(shop.photo.pc.l)")
    //                    }
    //        } catch {
    //            print("DEBUG: fetchRestaurants error \(error)")
    //        }
    //    }
    
    /// 指定されたShopをlikedShopsリストに追加する
    func likeShop(_ shop: Shop) {
        // 既にlikedShopsに存在する場合は追加しない
        guard !likedShops.contains(where: { $0.id == shop.id }) else {
            return
        }
        likedShops.append(shop)
        
        print("DEBUG🍎: Current likedShops:")
        for shop in likedShops {
            print(" - Name: \(shop.name), Address: \(shop.address), URL: \(shop.urls.pc)")
        }
    }
    /// LikeShopsListView用に、お気に入りのショップリストを提供
    func getLikedShops() -> [Shop] {
        return likedShops
    }
    /// BackCardボタンが押された時に、removedShopsの最後のShopを元のshopsに戻す
    //    func restoreLastRemovedShop() {
    //        guard let lastRemovedShop = removedShops.last else { return }
    //        removedShops.removeLast()
    //        shops.insert(lastRemovedShop, at: 0)
    //    }
}

