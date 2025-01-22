//
//  StoreMock.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

struct Store: Identifiable, Hashable {
    let id: String
    let storeName: String
    var distance: Int
    var profileImageURLs: [String]
    var genre: String
    var station_name: String
}
