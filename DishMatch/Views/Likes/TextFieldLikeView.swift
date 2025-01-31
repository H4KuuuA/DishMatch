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
            // TextFieldっぽいボタン
            Button(action: {
                isSearchPresented = true
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                        .padding(.leading, 10)
                    
                    if searchText.isEmpty {
                        Text("お店を検索")
                            .foregroundColor(.gray)
                            .padding(.leading, 5)
                    } else {
                        Text(searchText) // ✅ 検索ワードを表示
                            .foregroundColor(.black)
                            .padding(.leading, 5)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray5)))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    TextFieldLikeView(isSearchPresented: .constant(true), searchText: .constant("ラーメン"))
}
