//
//  CardModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

/// Storeはカードに関連するストアの情報を保持するモデル
struct CardModel {
    let store: Store

}
/// 各カードの一意の識別子を返す
extension CardModel: Identifiable, Hashable {
    var id: String {
        return store.id
    }
}
