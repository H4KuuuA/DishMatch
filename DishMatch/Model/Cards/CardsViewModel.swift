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

    // 一時的に削除されたShopを保存する配列
    private var removedShops: [Shop] = []
    // removedShopsに保存する最大数
    private let maxRemovedShopsCount = 5

    private let restaurantViewModel = RestaurantViewModel() // RestaurantViewModelを利用

    init() {
        Task {
            await fetchRestaurants() // fetchCardModelsをfetchRestaurantsに置き換え
        }
    }

    // `Shop` データをAPIから取得する
    func fetchRestaurants() async {
        do {
            await restaurantViewModel.fetchRestaurants() // APIからデータを取得
            self.shops = restaurantViewModel.restaurants // データを更新
        } catch {
            print("DEBUG: fetchRestaurants error \(error)")
        }
    }

    /// 指定されたShopをshopsから削除し、removedShopsに保存する
    func removeShop(_ shop: Shop) {
        guard let index = shops.firstIndex(where: { $0.id == shop.id }) else { return }
        // Shopを削除し、removedShopsに追加
        let removedShop = shops.remove(at: index)
        removedShops.append(removedShop)
        // removedShopsがmaxRemovedShopsCountを超えた場合、最古のShopを削除
        if removedShops.count > maxRemovedShopsCount {
            removedShops.removeFirst()
        }
        print("DEBUG: Removed shop with name: \(removedShop.name)")
    }

    /// BackCardボタンが押された時に、removedShopsの最後のShopを元のshopsに戻す
    func restoreLastRemovedShop() {
        guard let lastRemovedShop = removedShops.last else { return }
        removedShops.removeLast()
        shops.insert(lastRemovedShop, at: 0)
    }
}

