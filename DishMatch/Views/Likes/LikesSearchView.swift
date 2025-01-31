//
//  LikesSearchView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/31.
//

import SwiftUI

struct LikesSearchView: View {
    @Binding var isPresented: Bool
    @State private var searchText: String = ""
    @State private var searchHistory : [String] = []
    @State private var keyboardOffset: CGFloat = 0
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
    /// 検索実行 (仮)
    private func performSearch() {
        if !searchText.isEmpty {
            if !searchHistory.contains(searchText) {
                searchHistory.insert(searchText, at: 0) // 新しい検索履歴を先頭に追加
            }
        }
    }

    /// 履歴の削除
    private func removeHistory(at offsets: IndexSet) {
        searchHistory.remove(atOffsets: offsets)
    }
}

#Preview {
    LikesSearchView(isPresented: .constant(true))
}
