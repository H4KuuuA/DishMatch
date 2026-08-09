//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @StateObject private var errorQueue = ErrorQueue()
    @State private var viewID = UUID() // ビュー更新用の識別子
    @State private var isShowDiscoverSettings = false
    @State private var isFirstAppearance = true
    /// 友達とのマッチ演出から「お店を見てみる」を選んだ後に詳細を表示するための対象
    @State private var matchedShopToShowDetail: Shop?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // タイトルと絞り込みボタンを1行の独自ヘッダーにまとめる。
                // ナビゲーションバー＋ツールバーだとiOS26のLiquid Glassがボタンを拡大して
                // カードと詰まるため、ナビゲーションバーは隠して自前で描画する。
                header

                if restaurantViewModel.isLoading {
                    // 中身が小さいと VStack が親の中央に配置され、header(NavigationBar相当)まで
                    // 中央に降りてしまう。残り領域いっぱいに広げて header を上部に固定する。
                    ProgressView("データを読み込んでいます...")
                        .font(.title2)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if restaurantViewModel.shopList.isEmpty {
                    // こだわり条件を絞り込みすぎて0件になった場合、設定をやり直す
                    // 手段が無いと詰んでしまうが、絞り込みボタンは常に上部ヘッダーに
                    // 表示されているのでここではResetボタンのみでよい
                    VStack(spacing: 16) {
                        Text("表示する店舗がありません")
                            .foregroundColor(.gray)
                            .font(.title3)
                            .padding()
                        ResetCardButtonView(restaurantViewModel: restaurantViewModel, viewID: $viewID)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ZStack {
                        ForEach(Array(restaurantViewModel.shopList.enumerated()), id: \.element.id) { index, shop in
                            CardView(restaurantViewModel: restaurantViewModel, shop: shop)

                                .onChange(of: restaurantViewModel.shopList) {
                                    if restaurantViewModel.shopList.count <= 5 && !restaurantViewModel.isLoading {
                                        restaurantViewModel.fetchNextPage()
                                    }
                                }


                        }

                    }

                    // 左から「戻す」「None」「Like」「リロード」の並び。
                    // 絞り込みは左上のツールバーに移したため、ここには含めない
                    HStack(spacing: 32) {
                        UndoButtonView(restaurantViewModel: restaurantViewModel)
                        SwipeActionButtonView(restaurantViewModel: restaurantViewModel)
                        ResetCardButtonView(restaurantViewModel: restaurantViewModel, viewID: $viewID)
                    }
                }
            }
            .overlay(alignment: .top) {
                // 位置情報の取得失敗とAPI取得失敗が同時に起こりうるため、
                // .alertではなくキュー表示できるErrorBannerViewを使う
                ErrorBannerView(errorQueue: errorQueue)
                    .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear.frame(height: SizeConstants.customTabBarHeight)
            }
            // タイトルとボタンは上部の独自ヘッダー(header)で描画するため、
            // システムのナビゲーションバーは隠す（Liquid Glassの自動装飾を避ける）
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $isShowDiscoverSettings) {
                DiscoverySettingsView(restaurantViewModel: restaurantViewModel, viewID: $viewID)
            }
            // 友達の好みと一致した「本当のマッチ」の時だけこの演出を出す（Like自体はCardView側の軽い演出のみ）
            .fullScreenCover(item: $restaurantViewModel.friendMatch) { match in
                FriendMatchCelebrationView(
                    match: match,
                    onKeepSearching: {
                        restaurantViewModel.friendMatch = nil
                    },
                    onViewDetail: {
                        let shop = match.shop
                        restaurantViewModel.friendMatch = nil
                        // fullScreenCoverを閉じるアニメーションと重ならないよう少し待ってから次を開く
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            matchedShopToShowDetail = shop
                        }
                    }
                )
            }
            .fullScreenCover(item: $matchedShopToShowDetail) { shop in
                StoreProfileView(shop: shop)
            }
            // `viewID`を変えることでカードスタックの表示状態（CardView内の@Stateなど）を
            // リセットする。再検索自体はResetCardButtonView/DiscoverySettingsViewから
            // 直接fetchShopsを呼んで行う（`.onChange(of: viewID)`は、.id()によるView再構築の
            // タイミングと絡んで確実に発火しないことがあるため使わない）
            .id(viewID)
            .onAppear {
                if isFirstAppearance {
                    isFirstAppearance = false
                    restaurantViewModel.fetchShops(startIndex: 1) // 初回データ取得
                }
                //                // データ同期を非同期処理の完了後に実行
                //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // デバッグ用の遅延
                //                    viewModel.shops = restaurantViewModel.restaurants
                //                    print("DEBUG⭐️: Synced restaurants to viewModel.shops: \(viewModel.shops.map { $0.name })")
                //                }
            }
            .onChange(of: restaurantViewModel.lastError) { _, newValue in
                if let newValue {
                    errorQueue.report(newValue)
                }
            }
        }
    }

    /// 画面上部の独自ヘッダー。左に「DishMatch」タイトル、右に絞り込みボタン。
    private var header: some View {
        HStack {
            (Text("Dish")
                .foregroundStyle(.orange)
             + Text("Match")
                .foregroundStyle(.primary))
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            DiscoverSettingsButtonView(isShowDiscoverSettings: $isShowDiscoverSettings)
        }
        .padding(.horizontal)
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel(friendsViewModel: FriendsViewModel())
    restaurantViewModel.shopList = [
        MockShop.mockShop,
        MockShop.mockShop
    ]
    return CardStackView(restaurantViewModel: restaurantViewModel)
}
