//
//  TextFieldLikeView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct TextFieldLikeView: View {
    @Binding var isSearchPresented: Bool
    @Binding var searchText: String

    var body: some View {
        VStack {
            // テキストフィールド風のビュー
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .padding(.leading, 10)
                
                if searchText.isEmpty {
                    Text("お店を検索")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                } else {
                    Text(searchText)
                        .foregroundColor(Color("FC"))
                        .padding(.leading, 5)
                }
                
                Spacer()
                
                // クリアボタン (検索ワードがある場合のみ表示)
                if !searchText.isEmpty {
                    Button(action: {
                        searchText = ""
                        isSearchPresented = true 
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                    .padding(.trailing, 10)
                }
            }
            .padding(.vertical, 10)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
            .padding(.horizontal)
            .onTapGesture {
                isSearchPresented = true
            }
        }
    }
}

#Preview {
    TextFieldLikeView(isSearchPresented: .constant(true), searchText: .constant("ラーメン"))
}
