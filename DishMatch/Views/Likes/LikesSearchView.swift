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
                                .foregroundColor(Color.black.opacity(0.5)) // ✅ プレースホルダーの色を変更
                                .padding(.leading, 5)
                        }
                        TextField("", text: $searchText, onCommit: {
                            performSearch()
                        })
                        .font(.callout)
                        .foregroundStyle(Color.black)
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
                }
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .padding(.horizontal)
            }
            .padding(.top, 10)
            .background(Color("BG"))
            
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
                .listRowBackground(Color.white)
                .padding(.vertical, 4)
                
                // 履歴セクション
                if !searchHistory.isEmpty {
                    Section(header: HStack {
                        Text("履歴").font(.headline).bold()
                            .foregroundStyle(Color.black)
                        Spacer()
                        Button("すべて削除") {
                            searchHistory.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }) {
                        ForEach(searchHistory, id: \.self) { history in
                            Button {
                                searchText = history
                                performSearch()
                            } label: {
                                Text(history)
                            }
                        }
                        .onDelete(perform: removeHistory)
                    }
                    .listRowBackground(Color.white)
                    .padding(.vertical, 4)
                }
            }
            .listStyle(PlainListStyle()) // セル間の余白を減らす
            .background(Color("BG"))
            .tint(.orange)
            .padding(.bottom, keyboardOffset)
        }
        .onAppear {
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
