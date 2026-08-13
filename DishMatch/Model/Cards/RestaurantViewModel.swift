//
//  RestaurantViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

/// HotPepper検索へ実際に適用する絞り込み条件。AIおすすめの「段階的リラックス」で決まる。
/// genreCodes が「意図の硬い境界線」で、ページングやリラックスでもこの外へは広げない。
struct AppliedFilter {
    /// 検索対象のジャンルコード集合（primaryが先頭）。空なら絞り込みなし（ニュートラル）。
    var genreCodes: [String]
    /// キーワード。`keywordIsFilter`がtrueならAPIで絞り込み、falseなら並び順（一致店を上位）にだけ使う。
    var keyword: String?
    /// keywordをAPIの絞り込みに使うか。件数が足りないと段階的にfalseへ降格する。
    var keywordIsFilter: Bool
    /// こだわり条件（APIハード絞り込み）。件数が足りないと最初に外す。
    /// シチュエーションでは多様性維持のため「最重要1つ」だけをここに入れる。
    var particulars: Set<ParticularOption>
    /// broad（複数ジャンルをprimary厚めに加重マージ）か、specific（先頭ジャンルのみ）か。
    var isBroad: Bool
    /// 並び順(ランク)で効かせるこだわり。APIでは絞り込まず、これらを多く満たす店を上位へ寄せる。
    /// シチュエーションで「個室でハード絞り込み＋コース等はランク」を実現するために使う。
    var rankParticulars: [ParticularOption] = []

    /// 絞り込みなしのニュートラル（初回・通常ディスカバリー）。
    static let neutral = AppliedFilter(genreCodes: [], keyword: nil, keywordIsFilter: false, particulars: [], isBroad: false)
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
    /// ジャンル別の次に取得するstartIndex（ページング用）。ニュートラルは空文字""をキーに使う。
    private var genreCursor: [String: Int] = [:]
    /// ジャンル別のresultsAvailable（総件数）。カーソルが総件数を超えたらそのジャンルは打ち止め。
    private var genreTotal: [String: Int] = [:]
    /// リラックスの全段（厳しい→緩い）。ページングで現レベルを取り切ったら次の段へ降りて補充する。
    private var recommendationLadder: [AppliedFilter] = [.neutral]
    /// いま適用中の段のインデックス（`recommendationLadder`内）。
    private var ladderIndex = 0
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

    /// 店舗データをAPIから取得して1ページ目を表示する（初回・リロード）。
    /// 適用中の絞り込み（AIおすすめが決めたもの）があればそれを、無ければニュートラル（絞り込みなし）で読む。
    /// - Parameter startIndex: 互換のため残すが、現在は常に1ページ目を読み直す。
    func fetchShops(startIndex: Int = 1) {
        guard !isLoading else { return } // 既にロード中なら処理しない
        let filter = appliedFilter ?? .neutral
        Task { await loadFirstPage(filter: filter) }
    }

    /// 指定フィルタで1ページ目を取得し、カードスタックを差し替える。
    private func loadFirstPage(filter: AppliedFilter) async {
        guard !isLoading else { return }
        isLoading = true
        isFetchingNextPage = true
        defer {
            isLoading = false
            isFetchingNextPage = false
        }
        appliedFilter = filter
        // 通常ディスカバリー/リロードは単一段。ページングは同じ条件の続きを取り続ける。
        recommendationLadder = [filter]
        ladderIndex = 0
        resetCursors(for: filter)

        let (range, serviceAreaCode) = await resolveLocationParams()
        let budgetParam = settings.budgetAPICode
        do {
            let deck = try await fetchAndMerge(filter: filter, range: range, area: serviceAreaCode, budget: budgetParam)
            // 関連度の高い順（deckの先頭）を最前面（配列末尾）に置くため反転する。
            shopList = deck.reversed()
            currentPage = 1
            hasMorePages = filterHasMore()
        } catch {
            print("エラー: \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "お店を読み込めませんでした")
        }
    }

    /// この端末でオンデバイスAIおすすめが使えるか（iOS 26+ かつ Apple Intelligence 対応端末）。
    var isRecommendationAvailable: Bool { recommendationEngine.isAvailable }

    /// 今日の気分（任意）といいね履歴からAIに検索条件を提案させ、「段階的リラックス」で検索する。
    ///
    /// AIの条件をそのままANDで全部かけると結果が激減する（気分フレーズのkeywordはほぼ0件になる）。
    /// そこで **ジャンル集合は固定したまま** こだわり→keyword絞り込み の順に緩めて件数を確保する。
    /// ジャンル集合＝意図の硬い境界線なので、件数が足りなくても外へは絶対に広げない
    /// （全ジャンルフォールバックは廃止）。0件ならそのまま空表示にする（少なくても正しい方針）。
    /// AIが使えない・ジャンル無しの場合はニュートラル（絞り込みなし）で読む。
    /// - Parameter userPrompt: 今日の気分・リクエスト。空・nil なら履歴のみで判断する。
    func applyRecommendation(userPrompt: String?) async {
        guard !isLoading else { return }
        isRecommending = true
        let aiCriteria = await recommendationEngine.recommend(userPrompt: userPrompt, likedShops: favoriteShops)
        let criteria = seedWithInitialPreferenceIfNeeded(aiCriteria)
        recommendationReason = criteria?.reason
        isRecommending = false

        isLoading = true
        isFetchingNextPage = true
        defer {
            isLoading = false
            isFetchingNextPage = false
        }

        let (range, serviceAreaCode) = await resolveLocationParams()
        let budgetParam = settings.budgetAPICode

        // ジャンル集合を固定したまま緩める段（厳しい→緩い）。件数がしきい値以上になった最初の段を採用。
        // 全段は保持し、ページングで現レベルを取り切ったら次の段へ降りて補充する（fetchNextPage）。
        let ladder = relaxationLadder(for: criteria)
        var chosenIndex = ladder.count - 1
        var chosenDeck: [Shop] = []
        do {
            for (index, filter) in ladder.enumerated() {
                resetCursors(for: filter)
                let deck = try await fetchAndMerge(filter: filter, range: range, area: serviceAreaCode, budget: budgetParam)
                chosenIndex = index
                chosenDeck = deck
                // 集合全体のAPI総件数がしきい値以上なら、この段で確定。
                let totalAvailable = genreTotal.values.reduce(0, +)
                if totalAvailable >= Self.minRecommendationResults { break }
                if index == ladder.count - 1 { break }
            }
        } catch {
            print("エラー: \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "お店を読み込めませんでした")
            return
        }

        recommendationLadder = ladder
        ladderIndex = chosenIndex
        appliedFilter = ladder[chosenIndex]
        // 関連度の高い順（deckの先頭）を最前面（配列末尾）に置くため反転する。
        shopList = chosenDeck.reversed()
        currentPage = 1
        // 現レベルに続きがある、または次のレベルがあるなら、まだ補充できる。
        hasMorePages = filterHasMore() || ladderIndex < recommendationLadder.count - 1
    }

    /// 現在地/エリア指定に応じた range と serviceAreaCode を解決する。
    /// 現在地モードでは位置情報の許可要求と、失敗時のエラー報告もここで行う。
    /// - Parameter requestPermission: falseなら許可要求・エラー報告をスキップ（ページング時に多重報告しないため）。
    private func resolveLocationParams(requestPermission: Bool = true) async -> (range: String?, serviceAreaCode: String?) {
        switch settings.searchLocationMode {
        case .currentLocation:
            if requestPermission {
                let locationManager = LocationManager.shared
                await locationManager.requestLocationPermissionIfNeeded()
                // 位置情報取得の失敗とAPI取得の失敗は別要因のため、独立して報告しておく
                if let locationError = locationManager.locationError {
                    lastError = AppError.from(locationError, fallbackTitle: locationError.errorTitle)
                }
            }
            return (settings.selectedRange.rangeValue, nil)
        case .area:
            return (nil, settings.selectedServiceAreaCode)
        }
    }

    /// AIおすすめの条件を「厳しい→緩い」の段に展開する（ジャンル集合は全段で固定）。
    /// applyRecommendationが順に試し、件数がしきい値以上になった最初の段を採用する。
    ///
    /// **keywordはAPIの絞り込みには使わない**（ハード絞り込みは件数が激減するため）。keywordは常に
    /// 「並び順」専用に降格し、集合の全件を出しつつ一致店を上位に寄せる（「コーヒー」→カフェ全件）。
    ///
    /// 2軸のテーマを1つのladderで扱う:
    /// - 料理テーマ: genreCodesあり。こだわりは補助で、末尾から緩める。
    /// - シチュエーションテーマ（デート等）: genreCodes空（＝全ジャンル）。**こだわりが主役**で、
    ///   個室・夜景・コース…をANDで効かせ、件数が減ったら重要度の低い順（末尾）に1つずつ緩める。
    /// コールドスタート（いいね履歴なし）で、AIが具体ジャンルを出せなかった時に、
    /// 新規登録で選んだ「好きなジャンル（初期嗜好）」を検索の初期値として使う。
    /// 履歴が貯まれば recommend() の判断（履歴＞初期嗜好）が優先され、自然に上書きされる。
    private func seedWithInitialPreferenceIfNeeded(_ criteria: RecommendationCriteria?) -> RecommendationCriteria? {
        // 履歴がある、または既に具体ジャンルが決まっているならそのまま使う
        guard favoriteShops.isEmpty, (criteria?.genreCodes.isEmpty ?? true) else { return criteria }
        let prefs = UserProfile.shared.preferredGenreCodes
        guard !prefs.isEmpty else { return criteria }
        // genreCodes は最大3件想定。broad（複数ジャンルを加重マージ）で好みを広めに出す。
        let codes = Array(prefs.prefix(3))
        return RecommendationCriteria(
            genreCodes: codes,
            isBroad: codes.count > 1,
            keyword: criteria?.keyword,
            particulars: criteria?.particulars ?? [],
            reason: criteria?.reason ?? "登録した好みのジャンルから探しています"
        )
    }

    private func relaxationLadder(for criteria: RecommendationCriteria?) -> [AppliedFilter] {
        guard let criteria else { return [.neutral] }
        let codes = criteria.genreCodes
        let keyword = criteria.keyword
        let particulars = criteria.particulars  // 優先度の高い順
        let isBroad = criteria.isBroad

        // ジャンルもこだわりも無ければニュートラル（絞り込みなし）。
        if codes.isEmpty && particulars.isEmpty { return [.neutral] }

        var ladder: [AppliedFilter] = []

        if codes.isEmpty {
            // シチュエーション（デート等）: 全ジャンル横断。ジャンルの多様性を保つため、
            // ハード絞り込みは「最重要こだわり1つ」だけにし、残りは並び順(ランク)で効かせる。
            // 個室ANDコースのように複数をハード絞りすると和食・居酒屋に偏るのを防ぐ。
            if let top = particulars.first {
                ladder.append(AppliedFilter(genreCodes: [], keyword: nil, keywordIsFilter: false, particulars: [top], isBroad: false, rankParticulars: particulars))
            }
            // 緩め: こだわりのハード絞り無し（全ジャンル）。ランクは維持して適した店を上位に。
            ladder.append(AppliedFilter(genreCodes: [], keyword: nil, keywordIsFilter: false, particulars: [], isBroad: false, rankParticulars: particulars))
            return ladder
        }

        // 料理テーマ: ジャンル集合固定。
        // 希少な料理をドンピシャで出すため、keywordがあれば**最初にkeyword絞り込み段**を置く。
        // ここで十分件数（しきい値）が取れればそれを採用、足りなければ以降の段（keywordは並び順のみ）へ緩める。
        let hasKeyword = !(keyword ?? "").isEmpty
        if hasKeyword {
            ladder.append(AppliedFilter(genreCodes: codes, keyword: keyword, keywordIsFilter: true, particulars: Set(particulars), isBroad: isBroad))
        }
        // こだわりは補助で多い→少ない（末尾から）緩める。keywordは並び順のみ。
        var keep = particulars.count
        while keep > 0 {
            let subset = Set(particulars.prefix(keep))
            ladder.append(AppliedFilter(genreCodes: codes, keyword: keyword, keywordIsFilter: false, particulars: subset, isBroad: isBroad))
            keep -= 1
        }
        // 最後: こだわり無し（集合のみ）＝件数を最大化。
        ladder.append(AppliedFilter(genreCodes: codes, keyword: keyword, keywordIsFilter: false, particulars: [], isBroad: isBroad))
        return ladder
    }

    // MARK: - ジャンル集合の取得・マージ

    /// フィルタのジャンル別カーソルを1にリセットする（ニュートラルはキー""）。
    private func resetCursors(for filter: AppliedFilter) {
        genreCursor = [:]
        genreTotal = [:]
        let keys = filter.genreCodes.isEmpty ? [""] : filter.genreCodes
        for key in keys { genreCursor[key] = 1 }
    }

    /// まだ取得していないページが1つでも残っているか（ジャンル別カーソル基準）。
    private func filterHasMore() -> Bool {
        genreCursor.contains { code, next in
            let total = genreTotal[code] ?? Int.max
            return next <= total
        }
    }

    /// 現在のカーソルから、フィルタの各ジャンルを1ページずつ取得し、加重マージした「デッキ（関連度の高い順）」を返す。
    /// 取得のたびにカーソル・総件数を更新するので、続けて呼べば次ページになる。
    private func fetchAndMerge(filter: AppliedFilter, range: String?, area: String?, budget: String?) async throws -> [Shop] {
        let codes = filter.genreCodes.isEmpty ? [""] : filter.genreCodes
        let particularsParam = DiscoveryParticulars(selected: filter.particulars)
        let keywordParam = filter.keywordIsFilter ? filter.keyword : nil

        var perGenre: [(code: String, shops: [Shop])] = []
        for code in codes {
            let start = genreCursor[code] ?? 1
            // このジャンルが打ち止めなら空で足す（マージのバランスは他ジャンルで取る）。
            if let total = genreTotal[code], start > total {
                perGenre.append((code, []))
                continue
            }
            let genreParam = code.isEmpty ? nil : code
            let result = try await apiClient.fetchRestaurantData(
                keyword: keywordParam,
                range: range,
                genre: genreParam,
                budget: budget,
                particulars: particularsParam,
                serviceAreaCode: area,
                startIndex: start
            )
            genreTotal[code] = result.results.resultsAvailable
            genreCursor[code] = start + pageSize
            // 予算上限を超える店・既にいいね済みの店は出さない（同じ店の再提示を避ける）。
            let likedIDs = Set(favoriteShops.map { $0.id })
            let shops = result.results.shop.filter { self.passesBudgetCeiling($0) && !likedIDs.contains($0.id) }
            perGenre.append((code, shops))
        }
        return mergeByPreference(perGenre: perGenre, keyword: filter.keyword, isBroad: filter.isBroad, rankParticulars: filter.rankParticulars)
    }

    /// ジャンル別の結果を1本のデッキ（関連度の高い順）にまとめる。
    /// specific: 先頭ジャンルのみ。keyword一致店を上位・非一致店を下位に。
    /// broad: primary厚め（primaryを多め）の加重インターリーブ＋各ジャンル内でランク優先。
    private func mergeByPreference(perGenre: [(code: String, shops: [Shop])], keyword: String?, isBroad: Bool, rankParticulars: [ParticularOption]) -> [Shop] {
        // 各ジャンル内で keyword一致・こだわり充足の多い店を上位へ寄せる。
        let ordered = perGenre.map { (code: $0.code, shops: orderDeck($0.shops, keyword: keyword, rankParticulars: rankParticulars)) }

        var seen = Set<String>()
        var deck: [Shop] = []

        if !isBroad || ordered.count <= 1 {
            // specific（または単一ジャンル）：先頭から順に連結。
            for genre in ordered {
                for shop in genre.shops where seen.insert(shop.id).inserted {
                    deck.append(shop)
                }
            }
            return deck
        }

        // broad：primary(index 0)を2回、各secondaryを1回ずつ回すパターンで交互配置。
        var queues = ordered.map { Array($0.shops) }
        var pattern: [Int] = [0, 0]
        for i in 1..<queues.count { pattern.append(i) }

        var patternIndex = 0
        var remaining = queues.reduce(0) { $0 + $1.count }
        while remaining > 0 {
            let genreIndex = pattern[patternIndex % pattern.count]
            patternIndex += 1
            guard !queues[genreIndex].isEmpty else { continue }
            let shop = queues[genreIndex].removeFirst()
            remaining -= 1
            if seen.insert(shop.id).inserted { deck.append(shop) }
        }
        return deck
    }

    /// keyword一致・こだわり充足・写真ありで上位へ寄せた並びを返す（順序は安定）。
    /// 重み: keyword一致 +100（最重要）＞ こだわり1つ +10 ＞ 写真あり +1（微調整）。
    private func orderDeck(_ shops: [Shop], keyword: String?, rankParticulars: [ParticularOption]) -> [Shop] {
        let trimmed = keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasKeyword = !(trimmed ?? "").isEmpty
        // 写真ありは常に微加点するので、keyword/こだわりが無くても並べ替える価値がある。

        func score(_ shop: Shop) -> Int {
            var total = 0
            if hasKeyword, let trimmed, shopMatchesKeyword(shop, trimmed) { total += 100 }
            for option in rankParticulars where shopHasParticular(shop, option) { total += 10 }
            if !shop.photo.pc.l.isEmpty { total += 1 } // 写真ありを気持ち上位に
            return total
        }
        // enumerated の offset を使って同点は元順を保つ（安定ソート）。
        return shops.enumerated()
            .sorted { lhs, rhs in
                let ls = score(lhs.element), rs = score(rhs.element)
                if ls != rs { return ls > rs }
                return lhs.offset < rhs.offset
            }
            .map { $0.element }
    }

    /// 店名・ジャンル名・キャッチにkeywordが含まれるか（並び順用の緩い判定）。
    private func shopMatchesKeyword(_ shop: Shop, _ keyword: String) -> Bool {
        let haystack = [shop.name, shop.genre.name, shop.shopCatch]
        return haystack.contains { $0.localizedCaseInsensitiveContains(keyword) }
    }

    /// その店が指定のこだわりを満たすか（Shopが公開しているフィールドのみ判定。夜景等の非公開項目は常にfalse）。
    private func shopHasParticular(_ shop: Shop, _ option: ParticularOption) -> Bool {
        let value: String?
        switch option {
        case .privateRoom: value = shop.privateRoom
        case .course: value = shop.course
        case .freeDrink: value = shop.freeDrink
        case .freeFood: value = shop.freeFood
        case .tatami: value = shop.tatami
        case .horigotatsu: value = shop.horigotatsu
        case .charter: value = shop.charter
        case .child: value = shop.child
        case .nonSmoking: value = shop.nonSmoking
        case .lunch: value = shop.lunch
        case .parking: value = shop.parking
        case .card: value = shop.card
        case .wifi: value = shop.wifi
        default: value = nil // API絞り込みは可能だがShopに個別フィールドが無い項目（夜景・カクテル等）
        }
        guard let value, !value.isEmpty else { return false }
        return value != "なし"
    }

    /// 「予算 ≤ 選択」フィルタ。トグル「それ以下も含める」がON かつ 予算選択ありの時のみ効く。
    /// HotPepperの budget は最大2コードまでしか効かないため、下位ブラケット全部の絞り込みはここで行う。
    /// 予算未記載（code空／未知）の店は、下位の掘り出し物を落とさないよう含める。
    private func passesBudgetCeiling(_ shop: Shop) -> Bool {
        guard settings.isBudgetCeilingActive else { return true }
        let code = shop.budget?.code ?? ""
        guard !code.isEmpty, let bracket = BudgetType.from(code: code) else { return true }
        return bracket.priceRank <= settings.selectedBudget.priceRank
    }

    /// 次ページを取得してカードスタックに継ぎ足す。現レベルに続きがあればその続きを、
    /// 取り切っていたら次のレベル（より緩い段）へ降りて取得する。カードが尽きないよう、
    /// 実際に新しいお店を1件でも足せるまで（またはレベルを全て取り切るまで）繰り返す。
    func fetchNextPage() {
        guard !isLoading, !isFetchingNextPage else { return }
        guard hasMorePages else {
            print("⚠️ すべてのデータを取得済みです")
            return
        }
        isFetchingNextPage = true

        Task {
            defer { isFetchingNextPage = false }
            do {
                // ページング時は位置情報の許可要求・エラー報告をしない（多重報告を避ける）。
                let (range, serviceAreaCode) = await resolveLocationParams(requestPermission: false)
                let budgetParam = settings.budgetAPICode

                var added = 0
                var attempts = 0
                // 空ページ（既出とだぶってnewOnesが0）でも止まらないよう、少し粘って補充する。
                while added == 0 && attempts < 6 {
                    attempts += 1
                    // 現レベルを取り切っていたら次のレベルへ降りる。もう無ければ終了。
                    if !filterHasMore() {
                        guard advanceToNextLevel() else {
                            hasMorePages = false
                            break
                        }
                    }
                    let filter = appliedFilter ?? .neutral
                    let more = try await fetchAndMerge(filter: filter, range: range, area: serviceAreaCode, budget: budgetParam)
                    let existing = Set(shopList.map { $0.id })
                    let newOnes = more.filter { !existing.contains($0.id) }
                    if !newOnes.isEmpty {
                        // 新ページは既存より関連度が低い。前方（＝最前面から遠い側）へ、反転して挿入する。
                        shopList.insert(contentsOf: newOnes.reversed(), at: 0)
                        currentPage += 1
                        added = newOnes.count
                    }
                }
                hasMorePages = filterHasMore() || ladderIndex < recommendationLadder.count - 1
            } catch {
                print("エラー: \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: "続きのお店を読み込めませんでした")
            }
        }
    }

    /// 次のリラックス段（より緩い条件）へ降りてカーソルをリセットする。もう段が無ければ false。
    private func advanceToNextLevel() -> Bool {
        guard ladderIndex < recommendationLadder.count - 1 else { return false }
        ladderIndex += 1
        let next = recommendationLadder[ladderIndex]
        appliedFilter = next
        resetCursors(for: next)
        print("DEBUG 📌: 次のレベルへ降下 index=\(ladderIndex) genreCodes=\(next.genreCodes) particulars=\(next.particulars.map(\.rawValue))")
        return true
    }

    /// リストの最後の5つ前で次ページを取得
    func loadMoreShopsIfNeeded(currentShop: Shop) {
        guard hasMorePages else { return }

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
