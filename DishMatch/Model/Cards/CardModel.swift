//
//  CardModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

struct CardModel {
    let store: Store

}

extension CardModel: Identifiable, Hashable {
    var id: String {
        return store.id
    }
}
