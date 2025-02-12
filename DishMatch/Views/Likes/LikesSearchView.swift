//
//  LikesSearchView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/31.
//

import SwiftUI

struct LikesSearchView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    
    @Binding var isPresented: Bool
    @Binding var searchText: String
    
    @FocusState private var isTextFieldFocused: Bool
    
    @State private var keyboardOffset: CGFloat = 0
    var body: some View {
        VStack(spacing: 0) {
            // 検索バー + キャンセルボタン
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                    
                    ZStack(alignment: .leading) {
                        if searchText.isEmpty {
                            Text("エリア ジャンル 店名 など")
                                .foregroundColor(Color("FC").opacity(0.5))
                                .padding(.leading, 5)
                        }
                        TextField("", text: $searchText, onCommit: {
                            searchViewModel.performSearch(searchText)
                            isPresented = false
                        })
                        .focused($isTextFieldFocused)
                        .font(.callout)
                        .foregroundStyle(Color("FC"))
                        .padding(.vertical, 10)
                    }
                    
                    // ✖️ クリアボタン (検索ワードが空でない場合のみ表示)
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = "" // 入力内容をクリア
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.trailing, 8)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
                .frame(height: 40)
                .padding(.leading, 8)
                
                Button("キャンセル") {
                    isPresented = false
                    isTextFieldFocused = false
                }
                .foregroundColor(.blue)
                .padding(.horizontal)
            }
            .padding(.top, 10)
            .background(Color("WB"))
            
            // 検索オプション
            List {
                Section {
                    Button(action: { print("現在地検索") }) {
                        Label("現在地周辺", systemImage: "location.circle.fill")
                    }
                    
                    Button(action: { print("エリア検索") }) {
                        Label("エリアから探す", systemImage: "map.fill")
                    }
                    Button(action: { print("ジャンル検索") }) {
                        Label("ジャンルから探す", systemImage: "fork.knife")
                    }
                }
                .listRowBackground(Color("WB"))
                .padding(.vertical, 4)
                
                // 履歴セクション
                if !searchViewModel.searchHistory.isEmpty {
                    Section(header: historyHeader) {
                        ForEach(searchViewModel.searchHistory, id: \.self) { history in
                            Button {
                                searchText = history
                                searchViewModel.performSearch(history)
                            } label: {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(Color("FC").opacity(0.5))
                                        .padding(.trailing)
                                    Text(history)
                                }
                            }
                        }
                        .onDelete(perform: searchViewModel.removeHistory)
                    }
                    .listRowBackground(Color("WB"))
                    .padding(.vertical, 4)
                }

            }
            .listStyle(PlainListStyle()) // セル間の余白を減らす
            .background(Color("WB"))
            .tint(.orange)
            .padding(.bottom, keyboardOffset)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTextFieldFocused = true
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    withAnimation {
                        self.keyboardOffset = keyboardFrame.height - 40 // キーボードの高さ分、リストを上げる
                    }
                }
            }
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                withAnimation {
                    self.keyboardOffset = 0
                }
            }
        }
    }
    /// 履歴セクションのヘッダー
        private var historyHeader: some View {
            HStack {
                Text("履歴").font(.headline).bold()
                    .foregroundStyle(Color("FC"))
                Spacer()
                Button("すべて削除") {
                    searchViewModel.clearHistory()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
}

#Preview {
    LikesSearchView(searchViewModel: SearchViewModel(restaurantViewModel: RestaurantViewModel()),
                    isPresented: .constant(true),
                    searchText: .constant(""))
}
