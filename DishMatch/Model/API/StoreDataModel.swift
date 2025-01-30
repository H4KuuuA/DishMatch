//
//  StoreDataModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

struct StoreDataModel: Decodable {
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
struct Shop: Decodable,Identifiable,Equatable {
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
    }
    static func == (lhs: Shop, rhs: Shop) -> Bool {
           return lhs.id == rhs.id
       }
}

struct Genre: Decodable {
    // ジャンル名（例：和食、洋食など）
    let name: String
    // ジャンルのキャッチフレーズ
    let genreCatch: String

    enum CodingKeys: String, CodingKey {
        case name
        case genreCatch = "catch" // "catch" というJSONキーを genreCatch にマッピング
    }
}

struct Photo: Decodable {
    let pc: Pc
}

struct Pc: Decodable {
    let l: String
}

struct Urls: Decodable {
    let pc: String
}

enum MenuRangeType: CaseIterable {
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
