//
//  StoreDataModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

struct RestaurantDataModel: Decodable {
    let results: Results
}

// 結果データ(レストラン情報を含む「shop」配列を持つ)を格納する構造体
struct Results: Decodable {
    // 取得可能な合計店舗数
    let resultsAvailable: Int
    // 取得された件数（文字列として取得される）
    let resultsReturned: String
    // 取得開始位置
    let resultsStart: Int
    // レストランのリスト
    let shop: [Shop]

    enum CodingKeys: String, CodingKey {
        case resultsAvailable = "results_available"
        case resultsReturned = "results_returned"
        case resultsStart = "results_start"
        case shop
    }
}

// 各レストランの情報を表す構造体
// Codable: お気に入りリストをUserDefaultsにJSONとして保存・復元するためEncodableも必要
struct Shop: Codable,Identifiable,Equatable {
    /// 識別子
    var id = String()
    // レストラン名
    let name: String
    // ジャンル情報（ジャンル名、キャッチフレーズなど）
    let genre: Genre
    // レストランの写真情報
    let photo: Photo
    // 住所
    let address: String
    // 定休日
    let close: String
    // 営業時間
    let open: String
    // レストランのキャッチフレーズ
    let shopCatch: String
    // レストランのWebページURL
    let urls: Urls
    // 最寄り駅名
    let stationName: String
    // ディナー予算
    let budget: Budget?
    // アクセス情報（モバイル向けの短い表記）
    let mobile_access: String

    // MARK: - 詳細情報（HotPepper APIが返す拡張フィールド）
    // 保存済みお気に入り（旧JSON）にはキーが無いため、後方互換のためすべて任意にしている。

    /// 電車でのアクセス（`mobile_access` より詳しい説明）
    var access: String? = nil
    /// サブジャンル
    var subGenre: SubGenre? = nil
    /// 席数
    var capacity: Int? = nil
    /// 予算の補足コメント
    var budgetMemo: String? = nil
    /// その他・備考
    var otherMemo: String? = nil
    /// お店の詳細メモ
    var shopDetailMemo: String? = nil

    // こだわり・設備（値は "あり"/"なし"/"利用可"/"全面禁煙" などの文字列）
    var freeDrink: String? = nil
    var freeFood: String? = nil
    var course: String? = nil
    var privateRoom: String? = nil
    var horigotatsu: String? = nil
    var tatami: String? = nil
    var card: String? = nil
    var nonSmoking: String? = nil
    var charter: String? = nil
    var ktai: String? = nil
    var parking: String? = nil
    var barrierFree: String? = nil
    var wifi: String? = nil
    var lunch: String? = nil
    var midnight: String? = nil
    var child: String? = nil
    var pet: String? = nil
    var english: String? = nil
    var wedding: String? = nil
    var show: String? = nil
    var karaoke: String? = nil
    var band: String? = nil
    var tv: String? = nil

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case genre
        case photo
        case address
        case close
        case open
        // "catch" というJSONキーを shopCatch にマッピング
        case shopCatch = "catch"
        case urls
        // "station_name" というJSONキーを stationName にマッピング
        case stationName = "station_name"
        case budget
        // "mobile_access"というJSONキーを　mobile_access　にマッピング
        case mobile_access = "mobile_access"
        case access
        case subGenre = "sub_genre"
        case capacity
        case budgetMemo = "budget_memo"
        case otherMemo = "other_memo"
        case shopDetailMemo = "shop_detail_memo"
        case freeDrink = "free_drink"
        case freeFood = "free_food"
        case course
        case privateRoom = "private_room"
        case horigotatsu
        case tatami
        case card
        case nonSmoking = "non_smoking"
        case charter
        case ktai
        case parking
        case barrierFree = "barrier_free"
        case wifi
        case lunch
        case midnight
        case child
        case pet
        case english
        case wedding
        case show
        case karaoke
        case band
        case tv
    }
    static func == (lhs: Shop, rhs: Shop) -> Bool {
           return lhs.id == rhs.id
       }
}

/// 表示用の「設備・特徴」1項目。
struct ShopFeature: Identifiable {
    let id = UUID()
    let label: String
    let systemImage: String
}

extension Shop {
    /// 値が「利用可能・あり」を意味するかどうか（"なし"/"利用不可"/空 などを除外する）。
    static func isAvailable(_ value: String?) -> Bool {
        guard let value else { return false }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != "-" else { return false }
        if trimmed.contains("なし") || trimmed.contains("不可") { return false }
        return true
    }

    /// 詳細画面に表示する「設備・特徴」チップの一覧（利用可能なものだけ）。
    /// 禁煙・カード・駐車場は具体的な文言が重要なため、ここではなく個別の行で表示する。
    var features: [ShopFeature] {
        let candidates: [(ParticularOption, String?)] = [
            (.privateRoom, privateRoom),
            (.freeDrink, freeDrink),
            (.freeFood, freeFood),
            (.course, course),
            (.tatami, tatami),
            (.horigotatsu, horigotatsu),
            (.wifi, wifi),
            (.barrierFree, barrierFree),
            (.charter, charter),
            (.ktai, ktai),
            (.lunch, lunch),
            (.midnight, midnight),
            (.child, child),
            (.pet, pet),
            (.english, english),
            (.tv, tv),
            (.karaoke, karaoke),
            (.band, band),
            (.show, show),
            (.wedding, wedding)
        ]
        return candidates.compactMap { option, value in
            Shop.isAvailable(value) ? ShopFeature(label: option.label, systemImage: option.systemImage) : nil
        }
    }
}

struct Genre: Codable,Hashable {
    // ジャンルコード（例："G001"）。友達の好みジャンルとの一致判定に使う
    let code: String
    // ジャンル名（例：和食、洋食など）
    let name: String
    // ジャンルのキャッチフレーズ
    let genreCatch: String

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case genreCatch = "catch" // "catch" というJSONキーを genreCatch にマッピング
    }
}

struct Photo: Codable {
    let pc: Pc
}

struct Pc: Codable {
    let l: String
}

struct Urls: Codable {
    let pc: String
}
struct Budget: Codable {
    let code: String // 例: "B001"
    let name: String // 例: "～1000"
    var average: String? = nil // 平均予算の目安（例: "3000円"）

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case average
    }
}

/// サブジャンル（例: 居酒屋 > 海鮮居酒屋）。
struct SubGenre: Codable {
    let code: String
    let name: String
}

enum MenuRangeType: Int, CaseIterable {
    case range1
    case range2
    case range3
    case range4
    case range5

    // 各範囲に対応する距離（文字列）を返すプロパティ
    var range: String {
        switch self {
        case .range1:
            return "300m"
        case .range2:
            return "500m"
        case .range3:
            return "1,000m"
        case .range4:
            return "2,000m"
        case .range5:
            return "3,000m"
        }
    }

    // 各範囲に対応する範囲番号（文字列）を返すプロパティ
    var rangeValue: String {
        switch self {
        case .range1:
            return "1"
        case .range2:
            return "2"
        case .range3:
            return "3"
        case .range4:
            return "4"
        case .range5:
            return "5"
        }
    }
}

enum BudgetType: String, CaseIterable {
    case noPreference = "こだわらない"
    case under500 = "～500円"
    case from501To1000 = "501～1000円"
    case from1001To1500 = "1001～1500円"
    case from1501To2000 = "1501～2000円"
    case from2001To3000 = "2001～3000円"
    case from3001To4000 = "3001～4000円"
    case from4001To5000 = "4001～5000円"
    case from5001To7000 = "5001～7000円"
    case from7001To10000 = "7001～10000円"
    case from10001To15000 = "10001～15000円"
    case from15001To20000 = "15001～20000円"
    case from20001To30000 = "20001～30000円"
    case over30000 = "30001円～"

    /// 各予算に対応する検索用コードを返す
    var budgetCode: String {
        switch self {
        case .noPreference:
            return ""
        case .under500:
            return "B009"
        case .from501To1000:
            return "B010"
        case .from1001To1500:
            return "B011"
        case .from1501To2000:
            return "B001"
        case .from2001To3000:
            return "B002"
        case .from3001To4000:
            return "B003"
        case .from4001To5000:
            return "B004"
        case .from5001To7000:
            return "B005"
        case .from7001To10000:
            return "B006"
        case .from10001To15000:
            return "B007"
        case .from15001To20000:
            return "B012"
        case .from20001To30000:
            return "B013"
        case .over30000:
            return "B014"
        }
    }

    /// 予算コードから `BudgetType` を取得する
    static func from(code: String) -> BudgetType? {
        switch code {
        case "lst": return .noPreference
        case "B009": return .under500
        case "B010": return .from501To1000
        case "B011": return .from1001To1500
        case "B001": return .from1501To2000
        case "B002": return .from2001To3000
        case "B003": return .from3001To4000
        case "B004": return .from4001To5000
        case "B005": return .from5001To7000
        case "B006": return .from7001To10000
        case "B007": return .from10001To15000
        case "B012": return .from15001To20000
        case "B013": return .from20001To30000
        case "B014": return .over30000
        default: return nil
        }
    }
}
