//
//  TabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var restaurantViewModel: RestaurantViewModel
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var likesTabViewModel: LikesTabViewModel
    @StateObject private var friendsViewModel: FriendsViewModel
    /// チャット等の全画面表示中にタブバーを隠すための共有状態
    @StateObject private var tabBarVisibility = TabBarVisibility()
    @State private var selectedTab: AppTab = .discover
    /// キーボード表示中か。表示中はタブバーを隠す（safeAreaInsetのタブバーが
    /// キーボードの上に浮いてしまうのを防ぐ）。
    @State private var isKeyboardVisible = false

    /// - Parameter uid: ログイン中ユーザーのID。各データを Firestore の `users/{uid}` 配下に同期する。
    init(uid: String) {
        let friendsViewModel = FriendsViewModel(
            repository: RemoteFriendRepository(uid: uid),
            friendRequestRepository: FriendRequestRepository(),
            publicProfileRepository: PublicProfileRepository(),
            myUid: uid
        )
        let restaurantViewModel = RestaurantViewModel(
            friendsViewModel: friendsViewModel,
            favoritesRepository: RemoteFavoritesRepository(uid: uid)
        )
        _friendsViewModel = StateObject(wrappedValue: friendsViewModel)
        _restaurantViewModel = StateObject(wrappedValue: restaurantViewModel)
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(restaurantViewModel: restaurantViewModel))
        _likesTabViewModel = StateObject(wrappedValue: LikesTabViewModel(restaurantViewModel: restaurantViewModel))
    }

    var body: some View {
        ZStack {
            Color("BG").ignoresSafeArea()

            // 標準のTabViewは使わず、各タブの中身をZStackで重ねてopacityで
            // 出し分ける。こうすることでタブを行き来してもスクロール位置や
            // 入力途中のテキストなどの状態がリセットされない。
            ZStack {
                tabContent(for: .discover) {
                    CardStackView(restaurantViewModel: restaurantViewModel)
                }

                tabContent(for: .likes) {
                    LikesView(
                        searchViewModel: searchViewModel,
                        likesTabViewModel: likesTabViewModel,
                        restaurantViewModel: restaurantViewModel
                    )
                }

                tabContent(for: .friends) {
                    FriendsListView(friendsViewModel: friendsViewModel, restaurantViewModel: restaurantViewModel)
                }

                tabContent(for: .profile) {
                    UserProfileView(restaurantViewModel: restaurantViewModel)
                }
            }
        }
        // チャットなど全画面で使いたい画面（tabBarVisibility.isHidden = true）では
        // タブバーとそのための余白ごと消して、コンテンツを画面いっぱいに使えるようにする
        .environmentObject(tabBarVisibility)
        // オーバーレイではなくsafeAreaInsetで確保することで、リストや
        // ボタンなど各画面最下部の要素がタブバーの裏に隠れてタップ不能に
        // なるのを防ぐ（タブバー自体はガラス質感で背景が透けるので、
        // フローティングして見える見た目は保たれる）。
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // キーボード表示時、safeAreaInsetのタブバーはキーボード分だけ持ち上がって
            // 浮いてしまう（.ignoresSafeArea(.keyboard)を付けてもsafeAreaInst自体が
            // 追従するため止まらない）。LINE/インスタ同様、キーボード表示中はタブバーごと
            // 隠す。検索欄は各タブとも上部にあるため隠れても支障はない。
            if !tabBarVisibility.isHidden && !isKeyboardVisible {
                CustomTabBarView(selectedTab: $selectedTab)
            }
        }
        // キーボードの表示・非表示を監視してタブバーの出し分けに使う。
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
            isKeyboardVisible = true
        }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
            isKeyboardVisible = false
        }
    }

    /// 選択中のタブだけを表示・操作可能にしつつ、非選択タブはビューツリーに残して状態を保持する
    @ViewBuilder
    private func tabContent<Content: View>(for tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let isSelected = selectedTab == tab
        content()
            .opacity(isSelected ? 1 : 0)
            .allowsHitTesting(isSelected)
            .accessibilityHidden(!isSelected)
    }
}

#Preview {
    MainTabView(uid: "preview-uid")
}
