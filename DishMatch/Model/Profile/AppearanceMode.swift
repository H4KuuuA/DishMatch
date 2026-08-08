//
//  AppearanceMode.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import SwiftUI

/// アプリ設定画面で選択できる外観モード。@AppStorageにそのまま保存できるようString準拠にする。
enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "端末の設定に合わせる"
        case .light: return "ライト"
        case .dark: return "ダーク"
        }
    }

    /// `.preferredColorScheme(_:)` にそのまま渡せる値。systemの場合はnilにして端末設定に委ねる
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
