//
//  TextFieldLikeView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct TextFieldLikeView: View {
    var body: some View {
        VStack {
            // TextFieldっぽいボタン
            Button(action: {
                // ボタンが押されたときの処理
                // showNextView.toggle()
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    Text("お店を検索")
                        .foregroundColor(.gray)
                        .padding(.leading, 5)
                    
                    Spacer()
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.gray, lineWidth: 1))
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    TextFieldLikeView()
}
