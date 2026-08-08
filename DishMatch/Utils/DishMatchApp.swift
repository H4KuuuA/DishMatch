//
//  DishMatchApp.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

@main
struct DishMatchApp: App {
    // FirebaseApp.configure() を起動時に呼ぶための AppDelegate 接続
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // 認証状態をアプリ全体へ配信する
    @StateObject private var authService = AuthService()

    // 位置情報の許可要求は LocationManager の初期化時に走る。以前は起動時に先読み初期化して
    // いたが、ログイン必須化に伴いログイン画面の上に許可ダイアログが出てしまうため撤去した。
    // 位置情報は初回の店舗検索時（RestaurantViewModel.fetchShops）に LocationManager.shared へ
    // 初回アクセスする時点で遅延要求される。

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authService)
        }
    }
}
