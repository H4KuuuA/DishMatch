//
//  DiscoerySettings.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/26.
//

import Foundation

final class DiscoverySettings: ObservableObject {
    static let shared = DiscoverySettings()
    
    // 設定項目を @Published で宣言
    @Published var selectedRange: MenuRangeType = .range5
    @Published var selectedBudget: BudgetType = .noPreference
    @Published var isAllYouCanDrink: Bool = false
    @Published var isAllYouCanEat: Bool = false
    @Published var isPrivateRoomAvailable: Bool = false
    @Published var isTatamiRoomAvailable: Bool = false
    @Published var isParkingAvailable: Bool = false
    
    private init() {}
}

