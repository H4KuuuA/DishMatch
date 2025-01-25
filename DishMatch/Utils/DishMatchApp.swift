//
//  DishMatchApp.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

@main
struct DishMatchApp: App {
    init() {
            // アプリ起動時にLocationManagerを初期化
            _ = LocationManager.shared
        }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
