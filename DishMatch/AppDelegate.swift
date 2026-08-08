//
//  AppDelegate.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import UIKit
import FirebaseCore

/// Firebase をアプリ起動時に初期化するための最小の AppDelegate。
/// SwiftUI ライフサイクルの `DishMatchApp` から `@UIApplicationDelegateAdaptor` で接続する。
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
