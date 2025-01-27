//
//  LikeShopsListView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/27.
//

import SwiftUI

struct LikeShopsListView: View {
    @ObservedObject var viewModel: CardsViewModel
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack (spacing: 16) {
                    ForEach(viewModel.likedShops) { shop in
                        Button(action: {
                            // カードをタップしたときのアクションを記述
                            print("DEBUG: \(shop.name) tapped")
                        }) {
                            HStack(alignment: .top, spacing: 16) {
                                AsyncImage(url: URL(string: shop.photo.pc.l)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80) // サイズを固定
                                        .cornerRadius(8)
                                        .clipped() // フレーム外を切り取る
                                } placeholder: {
                                    Color.gray
                                        .frame(width: 80, height: 80) // プレースホルダー用サイズ
                                        .cornerRadius(8)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(shop.name)
                                        .font(.headline)
                                    HStack {
                                        Image(systemName: "fork.knife")
                                        Text("\(shop.genre.name)") // ジャンル名
                                        
                                        Text("|")
                                        Image(systemName: "mappin.and.ellipse")
                                        Text("\(shop.stationName)") // 最寄り駅名
                                    }
                                    .foregroundStyle(Color("FC").opacity(0.8))
                                    .font(.caption)
                                    .lineLimit(2)
                                    Spacer()
                                }
                                Spacer()
                            }
                            
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(
                            Rectangle())
                        .background(Color("WC"))
                        
                        Divider()
                    }
                }
                .padding()
            }
            .background(Color("WC"))
        }
    }
}
        
        #Preview {
            // モックデータ付きの CardsViewModel を使用してプレビュー
            let viewModel = CardsViewModel()
            viewModel.likeShop(MockShop.mockShop)
            viewModel.likeShop(MockShop.mockShop)
            
            return LikeShopsListView(viewModel: viewModel)
        }
