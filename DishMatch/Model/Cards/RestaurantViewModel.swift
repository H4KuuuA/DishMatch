//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

final class RestaurantViewModel: ObservableObject {
    @Published var shopList: [Shop] = []
    @Published var isLoading = false
    @Published var selectedSwipeAction: SwipeAction?
    @Published var favoriteShops: [Shop] = []

    private var dismissedShops: [Shop] = []
    private let maxDismissedShops = 5
    private let apiClient = APIClient()
    // シングルトンを利用
    private let settings = DiscoverySettings.shared

    /// キーワードやジャンルに基づいて店舗データをAPIから取得する
    /// - Parameters:
    ///   - keyword: 検索するキーワード（省略可能）
    ///   - genre: ジャンルのID（省略可能）
    func fetchShops(keyword: String? = nil, genre: String? = nil) {
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
                    self.shopList = result.results.shop
                    self.isLoading = false
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }

    /// 指定されたShopをshopListから削除し、dismissedShopsに保存する
    func dismissShop(_ shop: Shop) { // `removeShop` → `dismissShop`
        guard let index = shopList.firstIndex(where: { $0.id == shop.id }) else { return }
        let removedShop = shopList.remove(at: index)
        dismissedShops.append(removedShop)

        if dismissedShops.count > maxDismissedShops {
            dismissedShops.removeFirst()
        }
        print("DEBUG: Dismissed shop with name: \(removedShop.name)")
    }

    /// 指定されたShopをfavoriteShopsリストに追加する
    func addToFavorites(_ shop: Shop) {
        guard !favoriteShops.contains(where: { $0.id == shop.id }) else {
            return
        }
        DispatchQueue.main.async { // UIスレッドで更新
                self.favoriteShops.append(shop)
                print("DEBUG✅: Favorite shop added - \(shop.name)")
            }
        
        print("DEBUG🍎: Current favoriteShops:")
        for shop in favoriteShops {
            print(" - Name: \(shop.name), Address: \(shop.address), URL: \(shop.urls.pc)")
        }
    }

    /// お気に入りのShopリストを取得する
    func fetchFavoriteShops() -> [Shop] {
        return favoriteShops
    }
}


