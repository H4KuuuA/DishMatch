//
//  AppTab.swift
//  DishMatch
//
//  Created by Claude on 2026/08/05.
//

import Foundation

/// アプリ下部のカスタムタブバーが扱うタブの種類
enum AppTab: Int, CaseIterable, Identifiable {
    case discover
    case likes
    case friends
    case profile

    var id: Int { rawValue }

    /// 非選択時に表示するアウトラインのSF Symbol名
    var outlineSymbol: String {
        switch self {
        case .discover: return "fork.knife.circle"
        case .likes: return "heart"
        case .friends: return "person.2"
        case .profile: return "person.crop.circle"
        }
    }

    /// 選択時に表示する塗りつぶしのSF Symbol名
    var filledSymbol: String {
        switch self {
        case .discover: return "fork.knife.circle.fill"
        case .likes: return "heart.fill"
        case .friends: return "person.2.fill"
        case .profile: return "person.crop.circle.fill"
        }
    }
}
