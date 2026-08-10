//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

/// HotPepper検索へ実際に適用する絞り込み条件。AIおすすめの「段階的リラックス」で決まる。
struct AppliedFilter {
    var genreCode: String?
    var keyword: String?
    var particulars: Set<ParticularOption>
}

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

    /// AIが検索条件を生成中かどうか（「探す」ボタンのローディング表示に使う）
    @Published private(set) var isRecommending = false
    /// 直近のAIおすすめ理由（UI表示用）。AIを使わなかった場合は nil。
    @Published private(set) var recommendationReason: String?

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
    /// オンデバイスAIで検索条件を提案するエンジン。非対応OS/端末では nil を返す。
    private let recommendationEngine = RecommendationEngine()
    /// 実際にHotPepper検索へ適用中の絞り込み（AIおすすめの段階的リラックスで決定）。nilなら絞り込みなし。
    private var appliedFilter: AppliedFilter?
    /// おすすめ検索で「十分な件数」とみなすしきい値。これ未満なら条件を1つ緩めて再検索する。
    /// カードスタックを常に満杯（1ページ＝20枚）にしたいので1ページ分に設定している。
    /// 大きいほど件数重視で条件を緩めやすく、小さいほど条件を残しやすい（調整可）。
    private static let minRecommendationResults = 20
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
        // 適用中の絞り込み（AIおすすめが段階的リラックスで決めたもの）を引き継ぐ。無ければ絞り込まない。
        let genreParam = genre ?? appliedFilter?.genreCode
        let keywordParam = keyword ?? appliedFilter?.keyword
        let particularsParam = appliedFilter.map { DiscoveryParticulars(selected: $0.particulars) } ?? .none

        Task {
            do {
                let (range, serviceAreaCode) = await resolveLocationParams()
                // API からデータ取得
                let result = try await apiClient.fetchRestaurantData(keyword: keywordParam, range: range, genre: genreParam, budget: budgetParam, particulars: particularsParam, serviceAreaCode: serviceAreaCode, startIndex: startIndex)

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

    /// この端末でオンデバイスAIおすすめが使えるか（iOS 26+ かつ Apple Intelligence 対応端末）。
    var isRecommendationAvailable: Bool { recommendationEngine.isAvailable }

    /// 今日の気分（任意）といいね履歴からAIに検索条件を提案させ、「段階的リラックス」で検索する。
    ///
    /// AIの条件をそのままANDで全部かけると結果が激減する（気分フレーズのkeywordはほぼ0件になる）。
    /// そこで「厳しい条件→緩い条件」の順に検索し、十分な件数(minRecommendationResults)が返った
    /// 最初の段階を採用する。こうして条件が満たせる時はAIの提案を効かせ、足りない時だけ緩めて
    /// 常に十分な店舗数を確保する。AIが使えない場合は無条件（最大件数）になる。
    /// - Parameter userPrompt: 今日の気分・リクエスト。空・nil なら履歴のみで判断する。
    func applyRecommendation(userPrompt: String?) async {
        guard !isLoading else { return }
        isRecommending = true
        let criteria = await recommendationEngine.recommend(userPrompt: userPrompt, likedShops: favoriteShops)
        recommendationReason = criteria?.reason
        isRecommending = false

        isLoading = true
        isFetchingNextPage = true
        defer {
            isLoading = false
            isFetchingNextPage = false
        }

        let (range, serviceAreaCode) = await resolveLocationParams()
        let budgetParam = settings.selectedBudget == .noPreference ? nil : settings.selectedBudget.budgetCode

        // 厳しい→緩い の順に試し、件数がしきい値以上になった最初の段階を採用。
        // どれも満たさなければ最後（無条件）の結果を使う。
        let attempts = relaxationAttempts(for: criteria)
        var chosen = attempts[attempts.count - 1]
        var chosenShops: [Shop] = []
        var chosenTotal = 0
        do {
            for attempt in attempts {
                let result = try await apiClient.fetchRestaurantData(
                    keyword: attempt.keyword,
                    range: range,
                    genre: attempt.genreCode,
                    budget: budgetParam,
                    particulars: DiscoveryParticulars(selected: attempt.particulars),
                    serviceAreaCode: serviceAreaCode,
                    startIndex: 1
                )
                chosen = attempt
                chosenShops = result.results.shop
                chosenTotal = result.results.resultsAvailable
                if result.results.resultsAvailable >= Self.minRecommendationResults { break }
            }
        } catch {
            print("エラー: \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "お店を読み込めませんでした")
            return
        }

        appliedFilter = chosen
        shopList = chosenShops
        currentPage = 1
        totalResults = chosenTotal
        hasMorePages = shopList.count < totalResults
    }

    /// 現在地/エリア指定に応じた range と serviceAreaCode を解決する。
    /// 現在地モードでは位置情報の許可要求と、失敗時のエラー報告もここで行う。
    private func resolveLocationParams() async -> (range: String?, serviceAreaCode: String?) {
        switch settings.searchLocationMode {
        case .currentLocation:
            let locationManager = LocationManager.shared
            await locationManager.requestLocationPermissionIfNeeded()
            // 位置情報取得の失敗とAPI取得の失敗は別要因のため、独立して報告しておく
            if let locationError = locationManager.locationError {
                lastError = AppError.from(locationError, fallbackTitle: locationError.errorTitle)
            }
            return (settings.selectedRange.rangeValue, nil)
        case .area:
            return (nil, settings.selectedServiceAreaCode)
        }
    }

    /// AIおすすめの条件を「厳しい→緩い」の段階に展開する（applyRecommendationが順に試す）。
    private func relaxationAttempts(for criteria: RecommendationCriteria?) -> [AppliedFilter] {
        guard let criteria, let genre = criteria.genreCode else {
            // AIが使えない/ジャンル無し → 無条件（最大件数）
            return [AppliedFilter(genreCode: nil, keyword: nil, particulars: [])]
        }
        let keyword = criteria.keyword
        let particulars = criteria.particulars

        var attempts: [AppliedFilter] = []
        // 1. ジャンル＋キーワード＋こだわり（AIの提案そのまま）
        if keyword != nil || !particulars.isEmpty {
            attempts.append(AppliedFilter(genreCode: genre, keyword: keyword, particulars: particulars))
        }
        // 2. ジャンル＋こだわり（キーワードを外す＝一番結果を潰しやすい）
        if !particulars.isEmpty {
            attempts.append(AppliedFilter(genreCode: genre, keyword: nil, particulars: particulars))
        }
        // 3. ジャンルのみ
        attempts.append(AppliedFilter(genreCode: genre, keyword: nil, particulars: []))
        // 4. 無条件（ジャンルも外す）＝必ず件数を確保
        attempts.append(AppliedFilter(genreCode: nil, keyword: nil, particulars: []))
        return attempts
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
        // 1ページ目で採用された絞り込みをそのまま引き継ぐ（同じ条件で続きを取る）
        let genreParam = genre ?? appliedFilter?.genreCode
        let keywordParam = keyword ?? appliedFilter?.keyword
        let particularsParam = appliedFilter.map { DiscoveryParticulars(selected: $0.particulars) } ?? .none

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
                let result = try await apiClient.fetchRestaurantData(keyword: keywordParam, range: range, genre: genreParam, budget: budgetParam, particulars: particularsParam, serviceAreaCode: serviceAreaCode, startIndex: nextStartIndex)

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

        // マッチ判定はLikeした瞬間に相手の最新Like状況をサーバーから取得して行う（リアルタイム）。
        // キャッシュ頼みだとセッション中に相手がLikeした分を取りこぼすため、都度取得する。
        Task { [weak self] in
            guard let self else { return }
            let matchingFriends = await self.friendsViewModel.friendsMatchingLive(shop: shop)
            if !matchingFriends.isEmpty {
                self.friendMatch = FriendMatch(shop: shop, friends: matchingFriends)
            }
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
