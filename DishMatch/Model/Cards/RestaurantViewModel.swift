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
    // Likeしたお店。Firestore(`users/{uid}/favorites`)とリアルタイム同期し、
    // アプリを再起動しても・別端末でも出会ったお店が引き継がれる。
    // 値の反映はリスナー（favoritesRepository.observe）が担うため didSet では永続化しない。
    @Published var favoriteShops: [Shop] = []
    @Published private(set) var isFetchingNextPage = false
    /// 実際に訪れたお店のID集合。「行ったお店」画面で使う（favoriteShopsの部分集合）
    @Published var visitedShopIDs: Set<String> = []
    /// Likeしたお店が登録済み友達の好みと一致した時にセットする「友達とのマッチ」情報。
    /// 表示後はnilに戻す
    @Published var friendMatch: FriendMatch?

    /// 直前のスワイプを取り消せるかどうか（「戻す」ボタンの有効/無効に使う）
    @Published private(set) var canUndoLastSwipe = false
    /// 直近のAPIエラー。位置情報取得と店舗取得が別々に失敗しうるため、
    /// 呼び出し元（CardStackView）でErrorQueueに積んで多重エラーとして扱えるようにしている
    @Published var lastError: AppError?

    private var dismissedShops: [Shop] = [] {
        didSet { canUndoLastSwipe = !dismissedShops.isEmpty }
    }
    private let maxDismissedShops = 5
    private let apiClient = APIClient()
    private let settings = DiscoverySettings.shared
    private let friendsViewModel: FriendsViewModel
    /// いいね・「行った」状態の保存先。ログイン中は`RemoteFavoritesRepository`を渡す。
    /// nil の場合（プレビュー等）は同期せずメモリ上のみで動作する。
    private let favoritesRepository: FavoritesRepository?
    /// いいね一覧のリアルタイム購読トークン。deinit（nonisolated）から解除するため nonisolated(unsafe) で宣言する。
    nonisolated(unsafe) private var favoritesToken: RepositoryToken?
    /// リアルタイム購読中かどうか。購読中はリスナーが配列を反映するため手動操作を控える。
    private var isObservingFavorites = false
    private var currentPage = 1
    private let pageSize = 20
    private var totalResults = 0
    private var hasMorePages = true

    init(friendsViewModel: FriendsViewModel, favoritesRepository: FavoritesRepository? = nil) {
        self.friendsViewModel = friendsViewModel
        self.favoritesRepository = favoritesRepository
        startObservingFavorites()
    }

    deinit {
        favoritesToken?.cancel()
    }

    /// いいね一覧のリアルタイム購読を開始する。リポジトリ未設定なら何もしない。
    private func startObservingFavorites() {
        guard let favoritesRepository else { return }
        let token = favoritesRepository.observe { [weak self] shops, visitedIDs in
            Task { @MainActor in
                self?.favoriteShops = shops
                self?.visitedShopIDs = visitedIDs
                // 自分がLikeしたお店（ID）とジャンルを公開プロフィールへ反映し、友達側のマッチ判定に使えるようにする。
                // マッチは「同じお店をLikeした時」だけ成立させるため、お店IDが判定の主役
                UserProfile.shared.syncLikedShopIDs(Set(shops.map { $0.id }))
                UserProfile.shared.syncLikedGenres(Set(shops.map { $0.genre.code }))
            }
        }
        favoritesToken = token
        isObservingFavorites = token != nil
    }

    /// キーワードやジャンル、予算に基づいて店舗データをAPIから取得する（最初のページ）
    /// - Parameters:
    ///   - keyword: 検索するキーワード（例: "ラーメン"）【省略可能】
    ///   - genre: 検索するジャンルID（例: "G001"）【省略可能】
    ///   - budget: 検索する予算コード（例: "B003"）【省略可能】
    ///   - startIndex: 取得を開始するインデックス（デフォルトは1）
    func fetchShops(keyword: String? = nil, genre: String? = nil, budget: String? = nil, startIndex: Int = 1) {
        guard !isLoading else { return } // 既にロード中なら処理しない
        isLoading = true
        isFetchingNextPage = true
        // こだわらない場合は nil
        let budgetParam = settings.selectedBudget == .noPreference ? nil : settings.selectedBudget.budgetCode
        // 呼び出し元から明示的に指定がなければディスカバリー設定のジャンルを使う
        let genreParam = genre ?? settings.selectedGenreCode

        Task {
            do {
                let range: String?
                let serviceAreaCode: String?
                switch settings.searchLocationMode {
                case .currentLocation:
                    let locationManager = LocationManager.shared
                    await locationManager.requestLocationPermissionIfNeeded()
                    // 位置情報取得の失敗とAPI取得の失敗は別要因のため、両方とも
                    // 独立してErrorQueueに積めるようここで報告しておく
                    if let locationError = locationManager.locationError {
                        DispatchQueue.main.async {
                            self.lastError = AppError.from(locationError, fallbackTitle: locationError.errorTitle)
                        }
                    }
                    range = settings.selectedRange.rangeValue
                    serviceAreaCode = nil
                case .area:
                    range = nil
                    serviceAreaCode = settings.selectedServiceAreaCode
                }
                // API からデータ取得
                let result = try await apiClient.fetchRestaurantData(keyword: keyword, range: range, genre: genreParam, budget: budgetParam, particulars: settings.particulars, serviceAreaCode: serviceAreaCode, startIndex: startIndex)

                DispatchQueue.main.async {
                    if startIndex == 1 {
                        self.shopList = result.results.shop
                        self.currentPage = 1
                    } else {
                        self.shopList.insert(contentsOf: result.results.shop, at: 0)
                    }
                    
                    self.totalResults = result.results.resultsAvailable
                    self.hasMorePages = self.shopList.count < self.totalResults
                    self.isLoading = false
                    self.isFetchingNextPage = false
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isFetchingNextPage = false
                    self.lastError = AppError.from(error, fallbackTitle: "お店を読み込めませんでした")
                }
            }
        }
    }

    /// ページング用のデータを API から取得する
    func fetchNextPage(keyword: String? = nil, genre: String? = nil, budget: String? = nil) {
        guard !isLoading, !isFetchingNextPage else { return }
        guard shopList.count < totalResults else {
            print("⚠️ すべてのデータを取得済みです")
            return
        }
        
        isFetchingNextPage = true
        let nextStartIndex = (currentPage * pageSize) + 1
        
        print("DEBUG 📌: fetchNextPage() - startIndex = \(nextStartIndex)")
        
        // こだわらない場合は nil
        let budgetParam = settings.selectedBudget == .noPreference ? nil : settings.selectedBudget.budgetCode
        let genreParam = genre ?? settings.selectedGenreCode

        Task {
            do {
                let range: String?
                let serviceAreaCode: String?
                switch settings.searchLocationMode {
                case .currentLocation:
                    range = settings.selectedRange.rangeValue
                    serviceAreaCode = nil
                case .area:
                    range = nil
                    serviceAreaCode = settings.selectedServiceAreaCode
                }
                let result = try await apiClient.fetchRestaurantData(keyword: keyword, range: range, genre: genreParam, budget: budgetParam, particulars: settings.particulars, serviceAreaCode: serviceAreaCode, startIndex: nextStartIndex)

                DispatchQueue.main.async {
                    self.shopList.insert(contentsOf: result.results.shop, at: 0)
                    self.currentPage += 1
                    self.isFetchingNextPage = false
                }
            } catch {
                print("エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isFetchingNextPage = false
                    self.lastError = AppError.from(error, fallbackTitle: "続きのお店を読み込めませんでした")
                }
            }
        }
    }

    /// リストの最後の5つ前で次ページを取得
    func loadMoreShopsIfNeeded(currentShop: Shop, keyword: String? = nil, genre: String? = nil, budget: String? = nil) {
        guard hasMorePages else { return }
        
        if let lastIndex = shopList.firstIndex(where: { $0.id == currentShop.id }),
           lastIndex >= shopList.count - 5 {
            fetchNextPage(keyword: keyword, genre: genre, budget: budget)
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

    /// 直前にLike/Noneしたお店をカードスタックに戻す。「間違えてNoneしてしまった」を
    /// 取り消せるようにするための機能。Likeを取り消した場合はお気に入りからも外す
    func undoLastSwipe() {
        guard let lastRemoved = dismissedShops.popLast() else { return }
        if !isObservingFavorites {
            favoriteShops.removeAll { $0.id == lastRemoved.id }
        }
        // お気に入りに入っていなくても delete は冪等なので、そのまま外す
        performFavoritesWrite("操作を取り消せませんでした") { [favoritesRepository] in
            try await favoritesRepository?.remove(shopID: lastRemoved.id)
        }
        shopList.append(lastRemoved)
    }

    /// 気に入りに追加。登録済み友達の好みと一致していれば「友達とのマッチ」を成立させる
    func addToFavorites(_ shop: Shop) {
        guard !favoriteShops.contains(where: { $0.id == shop.id }) else { return }
        // リアルタイム購読中はリスナーが配列へ反映するため、手動追加はしない
        if !isObservingFavorites {
            favoriteShops.append(shop)
        }
        print("DEBUG✅: Favorite shop added - \(shop.name)")
        performFavoritesWrite("お気に入りに保存できませんでした") { [favoritesRepository] in
            try await favoritesRepository?.add(shop)
        }

        // マッチ演出は即座に出したいので同期を待たずに判定する
        let matchingFriends = friendsViewModel.friendsMatching(shop: shop)
        if !matchingFriends.isEmpty {
            friendMatch = FriendMatch(shop: shop, friends: matchingFriends)
        }
    }

    /// お気に入りのリストを取得
    func fetchFavoriteShops() -> [Shop] {
        return favoriteShops
    }

    /// お気に入りから削除する（いいね一覧でのスワイプ削除に使う）
    func removeFromFavorites(_ shop: Shop) {
        if !isObservingFavorites {
            favoriteShops.removeAll { $0.id == shop.id }
            visitedShopIDs.remove(shop.id)
        }
        performFavoritesWrite("お気に入りから削除できませんでした") { [favoritesRepository] in
            try await favoritesRepository?.remove(shopID: shop.id)
        }
    }

    /// 指定したお店を「行った」状態に切り替える（既に行った状態なら解除する）
    func toggleVisited(_ shop: Shop) {
        let willBeVisited = !visitedShopIDs.contains(shop.id)
        if !isObservingFavorites {
            if willBeVisited {
                visitedShopIDs.insert(shop.id)
            } else {
                visitedShopIDs.remove(shop.id)
            }
        }
        performFavoritesWrite("「行った」の更新に失敗しました") { [favoritesRepository] in
            try await favoritesRepository?.setVisited(shopID: shop.id, visited: willBeVisited)
        }
    }

    /// Firestoreへの書き込みを実行し、失敗時は lastError に積んで
    /// CardStackView 側の ErrorBannerView でユーザーに通知する。
    private func performFavoritesWrite(_ failureTitle: String, _ operation: @escaping () async throws -> Void) {
        Task {
            do {
                try await operation()
            } catch {
                print("DEBUG: お気に入り同期エラー \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: failureTitle)
            }
        }
    }
}
