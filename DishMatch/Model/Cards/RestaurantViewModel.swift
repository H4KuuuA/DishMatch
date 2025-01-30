//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

@MainActor
final class RestaurantViewModel: ObservableObject {
    @Published var shopList: [Shop] = []
    @Published var isLoading = false
    @Published var selectedSwipeAction: SwipeAction?
    @Published var favoriteShops: [Shop] = []
    @Published private(set) var isFetchingNextPage = false
    
    private var dismissedShops: [Shop] = []
    private let maxDismissedShops = 5
    private let apiClient = APIClient()
    private let settings = DiscoverySettings.shared
    private var currentPage = 1
    private let pageSize = 20
    private var totalResults = 0 // APIからの全体のデータ数
    private var hasMorePages = true // これ以上ページがあるかどうか
    
    /// キーワードやジャンルに基づいて店舗データをAPIから取得する（最初のページ）
    /// - Parameters:
    /// - keyword: 検索するキーワード（例: "ラーメン"）【省略可能】
    /// - genre: 検索するジャンルID（例: "G001"）【省略可能】
    ///　- startIndex: 取得を開始するインデックス（デフォルトは1）
    func fetchShops(keyword: String? = nil, genre: String? = nil, startIndex: Int = 1) {
        guard !isLoading else { return } // 既にロード中なら処理しない
        isLoading = true
        isFetchingNextPage = true
        
        Task {
            do {
                let locationManager = LocationManager.shared
                await locationManager.requestLocationPermissionIfNeeded()
                let range = settings.selectedRange.rangeValue
                // API からデータ取得
                let result = try await apiClient.fetchRestaurantData(keyword: keyword, range: range, genre: genre, startIndex: startIndex)
                
                DispatchQueue.main.async {
                    if startIndex == 1 {
                        self.shopList = result.results.shop
                        // 初回のみ currentPage をリセット
                        self.currentPage = 1
                    } else {
                        self.shopList.insert(contentsOf: result.results.shop, at: 0)
                    }
                    
                    self.totalResults = result.results.resultsAvailable
                    // まだデータがあるか判定
                    self.hasMorePages = self.shopList.count < self.totalResults
                    self.isLoading = false
                    self.isFetchingNextPage = false
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isFetchingNextPage = false
                }
            }
        }
    }
    
    
    /// ページング用のデータを API から取得する
    func fetchNextPage() {
        // 初回ロード完了後にのみ実行
        guard !isLoading, !isFetchingNextPage else { return }
        guard shopList.count < totalResults else {
            print("⚠️ すべてのデータを取得済みです")
            return
        }
        
        isFetchingNextPage = true
        let nextStartIndex = (currentPage * pageSize) + 1
        
        print("DEBUG 📌: fetchNextPage() - startIndex = \(nextStartIndex)")
        
        Task {
            do {
                let range = settings.selectedRange.rangeValue
                let result = try await apiClient.fetchRestaurantData(keyword: nil, range: range, genre: nil, startIndex: nextStartIndex)
                
                DispatchQueue.main.async {
                    self.shopList.insert(contentsOf: result.results.shop, at: 0)
                    self.currentPage += 1
                    self.isFetchingNextPage = false
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isFetchingNextPage = false
                }
            }
        }
    }
    
    /// リストの最後の5つ前で次ページを取得
    func loadMoreShopsIfNeeded(currentShop: Shop) {
        guard hasMorePages else { return } // これ以上データがないならリクエストしない
        
        if let lastIndex = shopList.firstIndex(where: { $0.id == currentShop.id }),
           lastIndex >= shopList.count - 5 {
            fetchNextPage()
        }
    }
    
    /// 指定されたShopをリストから削除し、dismissedShopsに保存
    func dismissShop(_ shop: Shop) {
        guard let index = shopList.firstIndex(where: { $0.id == shop.id }) else { return }
        let removedShop = shopList.remove(at: index)
        dismissedShops.append(removedShop)
        
        if dismissedShops.count > maxDismissedShops {
            dismissedShops.removeFirst()
        }
        print("DEBUG: Dismissed shop with name: \(removedShop.name)")
    }
    
    /// 気に入りに追加
    func addToFavorites(_ shop: Shop) {
        guard !favoriteShops.contains(where: { $0.id == shop.id }) else { return }
        DispatchQueue.main.async {
            self.favoriteShops.append(shop)
            print("DEBUG✅: Favorite shop added - \(shop.name)")
        }
    }
    
    /// お気に入りのリストを取得
    func fetchFavoriteShops() -> [Shop] {
        return favoriteShops
    }
}
