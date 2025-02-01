//
//  LikesViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/02/01.
//

import Foundation

class SearchViewModel: ObservableObject {
    @Published var searchHistory: [String] = []
    
    /// 検索履歴を追加
    func addSearchHistory(_ text: String) {
        guard !text.isEmpty, !searchHistory.contains(text) else { return }
        searchHistory.insert(text, at: 0)
    }
    
    /// 検索を実行（`LikesSearchView` から呼ぶだけ）
    func performSearch(_ text: String) {
        if !text.isEmpty {
            addSearchHistory(text)
        }
    }
    
    /// 検索履歴を削除
    func removeHistory(at offsets: IndexSet) {
        searchHistory.remove(atOffsets: offsets)
    }
    
    /// 検索履歴をクリア
    func clearHistory() {
        searchHistory.removeAll()
    }
}
