//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    var body: some View {
        VStack {
            TextFieldLikeView()
            GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
            
            ScrollView {
                VStack (alignment: .center, spacing: 20){
                    Spacer()
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.gray.opacity(0.5))
                        .font(.system(size: 30))
                    Text("店舗情報の取得に失敗しました。再試行してください。")
                        .foregroundColor(.gray.opacity(0.8))
                        .padding(.horizontal, 20)
                }
            }
        }
    }
}

#Preview {
    LikesView()
}
