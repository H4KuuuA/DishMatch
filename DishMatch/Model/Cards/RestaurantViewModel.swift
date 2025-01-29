//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

final class RestaurantViewModel: ObservableObject {
    @Published var restaurants: [Shop] = []
    @Published var isLoading = false
    @Published var buttonSwipeAction: SwipeAction? // スワイプアクションを保持
    @Published var likedShops: [Shop] = []
    
    private var removedShops: [Shop] = []
    private let maxRemovedShopsCount = 5
    private let apiClient = APIClient()
    private let settings = DiscoverySettings.shared // シングルトンを利用

    func fetchRestaurants(keyword: String? = nil, genre: String? = nil) {
        isLoading = true
        Task {
            do {
                // 位置情報を取得
                let locationManager = LocationManager.shared
                await locationManager.requestLocationPermissionIfNeeded() // 位置情報が取得されるまで待機

                // シングルトンから選択された range の範囲値を取得
                let range = settings.selectedRange.rangeValue

                // APIからデータを取得
                let result = try await apiClient.fetchRestaurantData(keyword: keyword, range: range, genre: genre)
                DispatchQueue.main.async {
                    self.restaurants = result.results.shop // データを更新
                    self.isLoading = false                // ローディング終了
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
    /// 指定されたShopをrestaurantsから削除し、removedShopsに保存する
        func removeShop(_ shop: Shop) {
            guard let index = restaurants.firstIndex(where: { $0.id == shop.id }) else { return }
            // Shopを削除し、removedShopsに追加
            let removedShop = restaurants.remove(at: index)
            removedShops.append(removedShop)
            // removedShopsがmaxRemovedShopsCountを超えた場合、最古のShopを削除
            if removedShops.count > maxRemovedShopsCount {
                removedShops.removeFirst()
            }
            print("DEBUG: Removed shop with name: \(removedShop.name)")
        }
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
}

