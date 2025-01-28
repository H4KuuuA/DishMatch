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
                if viewModel.likedShops.isEmpty {
                    Text("お気に入りがまだありません")
                        .foregroundColor(.gray)
                        .font(.headline)
                        .padding()
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.likedShops, id: \.id) { shop in
                            Button(action: {
                                print("DEBUG: \(shop.name) tapped")
                            }) {
                                HStack(alignment: .top, spacing: 16) {
                                    // 非同期画像読み込み
                                    AsyncImage(url: URL(string: shop.photo.pc.l)) { phase in
                                        switch phase {
                                        case .empty:
                                            ProgressView()
                                                .frame(width: 80, height: 80)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        case .success(let image):
                                            image
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .cornerRadius(8)
                                                .clipped()
                                        case .failure:
                                            Image(systemName: "photo")
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 80, height: 80)
                                                .background(Color.gray.opacity(0.3))
                                                .cornerRadius(8)
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }

                                    // 店舗情報
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(shop.name)
                                            .font(.headline)
                                            .lineLimit(1)

                                        HStack {
                                            Image(systemName: "fork.knife")
                                            Text("\(shop.genre.name)")
                                            Text("|")
                                            Image(systemName: "mappin.and.ellipse")
                                            Text("\(shop.stationName)")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(Color("FC").opacity(0.8))
                                        .lineLimit(1)
                                    }
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            .background(Color("WB"))
                            .cornerRadius(8)
                            Divider()
                        }
                    }
                    .padding()
                }
            }
            .background(Color("WB"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    let viewModel = CardsViewModel()
    viewModel.likeShop(MockShop.mockShop)
    viewModel.likeShop(MockShop.mockShop)

    return LikeShopsListView(viewModel: viewModel)
}
