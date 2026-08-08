//
//  ParticularOption.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import Foundation

/// ホットペッパーグルメサーチAPIが対応する「こだわり」絞り込み条件。
/// APIパラメータは各項目 `1` で「あり」に絞り込み、未指定なら絞り込まない。
enum ParticularOption: String, CaseIterable, Identifiable, Codable {
    case freeDrink
    case freeFood
    case course
    case cocktail
    case shochu
    case sake
    case wine
    case sommelier
    case privateRoom
    case tatami
    case horigotatsu
    case barrierFree
    case parking
    case nonSmoking
    case wifi
    case tv
    case openAir
    case nightView
    case show
    case karaoke
    case band
    case equipment
    case charter
    case wedding
    case child
    case pet
    case card
    case english
    case ktai
    case lunch
    case midnight
    case midnightMeal

    var id: String { rawValue }

    /// HotPepper APIのクエリパラメータ名
    var apiParameterName: String {
        switch self {
        case .freeDrink: return "free_drink"
        case .freeFood: return "free_food"
        case .course: return "course"
        case .cocktail: return "cocktail"
        case .shochu: return "shochu"
        case .sake: return "sake"
        case .wine: return "wine"
        case .sommelier: return "sommelier"
        case .privateRoom: return "private_room"
        case .tatami: return "tatami"
        case .horigotatsu: return "horigotatsu"
        case .barrierFree: return "barrier_free"
        case .parking: return "parking"
        case .nonSmoking: return "non_smoking"
        case .wifi: return "wifi"
        case .tv: return "tv"
        case .openAir: return "open_air"
        case .nightView: return "night_view"
        case .show: return "show"
        case .karaoke: return "karaoke"
        case .band: return "band"
        case .equipment: return "equipment"
        case .charter: return "charter"
        case .wedding: return "wedding"
        case .child: return "child"
        case .pet: return "pet"
        case .card: return "card"
        case .english: return "english"
        case .ktai: return "ktai"
        case .lunch: return "lunch"
        case .midnight: return "midnight"
        case .midnightMeal: return "midnight_meal"
        }
    }

    /// UI表示用の短いラベル
    var label: String {
        switch self {
        case .freeDrink: return "飲み放題"
        case .freeFood: return "食べ放題"
        case .course: return "コースあり"
        case .cocktail: return "カクテル充実"
        case .shochu: return "焼酎充実"
        case .sake: return "日本酒充実"
        case .wine: return "ワイン充実"
        case .sommelier: return "ソムリエ在籍"
        case .privateRoom: return "個室"
        case .tatami: return "座敷"
        case .horigotatsu: return "掘りごたつ"
        case .barrierFree: return "バリアフリー"
        case .parking: return "駐車場"
        case .nonSmoking: return "禁煙席"
        case .wifi: return "Wi-Fi"
        case .tv: return "TV・プロジェクター"
        case .openAir: return "オープンエア"
        case .nightView: return "夜景がきれい"
        case .show: return "ライブ・ショー"
        case .karaoke: return "カラオケ"
        case .band: return "バンド演奏可"
        case .equipment: return "エンタメ設備"
        case .charter: return "貸切可"
        case .wedding: return "二次会対応"
        case .child: return "子供連れOK"
        case .pet: return "ペット可"
        case .card: return "カード可"
        case .english: return "英語メニュー"
        case .ktai: return "携帯OK"
        case .lunch: return "ランチあり"
        case .midnight: return "深夜営業"
        case .midnightMeal: return "深夜も食事OK"
        }
    }

    /// UI表示用のSF Symbol名
    var systemImage: String {
        switch self {
        case .freeDrink: return "wineglass.fill"
        case .freeFood: return "fork.knife"
        case .course: return "list.bullet.rectangle.fill"
        case .cocktail: return "cup.and.saucer.fill"
        case .shochu: return "flame.fill"
        case .sake: return "drop.fill"
        case .wine: return "wineglass"
        case .sommelier: return "person.text.rectangle.fill"
        case .privateRoom: return "door.left.hand.closed"
        case .tatami: return "house.fill"
        case .horigotatsu: return "sofa.fill"
        case .barrierFree: return "figure.roll"
        case .parking: return "parkingsign.circle.fill"
        case .nonSmoking: return "nosign"
        case .wifi: return "wifi"
        case .tv: return "tv.fill"
        case .openAir: return "sun.max.fill"
        case .nightView: return "moon.stars.fill"
        case .show: return "music.mic"
        case .karaoke: return "music.note.list"
        case .band: return "music.quarternote.3"
        case .equipment: return "gamecontroller.fill"
        case .charter: return "person.3.fill"
        case .wedding: return "heart.circle.fill"
        case .child: return "figure.and.child.holdinghands"
        case .pet: return "pawprint.fill"
        case .card: return "creditcard.fill"
        case .english: return "globe"
        case .ktai: return "iphone"
        case .lunch: return "sun.horizon.fill"
        case .midnight: return "moon.fill"
        case .midnightMeal: return "moon.zzz.fill"
        }
    }

    /// こだわり選択画面でのグルーピング用カテゴリ
    var category: ParticularCategory {
        switch self {
        case .freeDrink, .freeFood, .course, .cocktail, .shochu, .sake, .wine, .sommelier:
            return .foodAndDrink
        case .privateRoom, .tatami, .horigotatsu, .barrierFree, .parking, .nonSmoking, .wifi, .tv:
            return .room
        case .openAir, .nightView, .show, .karaoke, .band, .equipment, .charter, .wedding:
            return .scene
        case .child, .pet, .card, .english, .ktai, .lunch, .midnight, .midnightMeal:
            return .convenience
        }
    }
}

/// こだわり選択画面でのセクション見出し用カテゴリ
enum ParticularCategory: String, CaseIterable, Identifiable {
    case foodAndDrink = "お店・お酒"
    case room = "設備・部屋"
    case scene = "シーン"
    case convenience = "利便性"

    var id: String { rawValue }
}
