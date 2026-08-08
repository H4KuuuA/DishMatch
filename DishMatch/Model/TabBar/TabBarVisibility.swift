//
//  TabBarVisibility.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// カスタムタブバー（CustomTabBarView）の表示/非表示をアプリ全体で共有するための状態。
/// チャット画面のように画面いっぱいを使いたい画面が、表示中だけタブバーを隠すのに使う。
@MainActor
final class TabBarVisibility: ObservableObject {
    @Published var isHidden = false
}
