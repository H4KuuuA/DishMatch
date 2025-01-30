////
////  RestaurantListView.swift
////  DishMatch
////
////  Created by 大江悠都 on 2025/01/25.
////
//
//import SwiftUI
//
//struct RestaurantListView: View {
//    @StateObject private var viewModel = RestaurantViewModel()
//    private var apiClient = APIClient()
//    @State private var restaurants: [Shop] = []
//    @State private var isLoading = false
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                if isLoading {
//                    ProgressView("データを取得中...") 
//                        .padding()
//                } else {
//                    List(restaurants) { restaurant in
//                        NavigationLink(destination: RestaurantDetailView(shop: restaurant)) {
//                            RestaurantRowView(restaurant: restaurant)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("レストラン一覧")
//            .onAppear {
//                viewModel.fetchRestaurants() // データを取得
//            }
//        }
//    }
//}
//
//// レストランの情報を1行で表示するカスタムビュー
//struct RestaurantRowView: View {
//    let restaurant: Shop
//    
//    var body: some View {
//        HStack {
//            AsyncImage(url: URL(string: restaurant.photo.pc.l)) { image in
//                image
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 80, height: 80)
//                    .cornerRadius(10)
//            } placeholder: {
//                ProgressView()
//                    .frame(width: 80, height: 80)
//            }
//            
//            VStack(alignment: .leading, spacing: 5) {
//                Text(restaurant.name)
//                    .font(.headline)
//                    .lineLimit(1)
//                
//                Text(restaurant.genre.name)
//                    .font(.subheadline)
//                    .foregroundColor(.gray)
//                
//                Text("最寄駅: \(restaurant.stationName)")
//                    .font(.caption)
//                    .foregroundColor(.gray)
//            }
//        }
//        .padding(.vertical, 5)
//    }
//}
//
//// レストランの詳細情報を表示するビュー
//struct RestaurantDetailView: View {
//    let shop: Shop
//    
//    var body: some View {
//        ScrollView {
//            VStack(spacing: 20) {
//                AsyncImage(url: URL(string: shop.photo.pc.l)) { image in
//                    image
//                        .resizable()
//                        .aspectRatio(contentMode: .fit)
//                } placeholder: {
//                    ProgressView()
//                        .frame(maxWidth: .infinity, maxHeight: 200)
//                }
//                
//                VStack(alignment: .leading, spacing: 10) {
//                    Text(shop.name)
//                        .font(.title)
//                        .fontWeight(.bold)
//                    
//                    Text("ジャンル: \(shop.genre.name)")
//                        .font(.subheadline)
//                    
//                    Text("最寄駅: \(shop.stationName)")
//                        .font(.subheadline)
//                    
//                    Text("住所: \(shop.address)")
//                        .font(.body)
//                    
//                    Text("営業時間: \(shop.open)")
//                        .font(.body)
//                    
//                    Text("定休日: \(shop.close)")
//                        .font(.body)
//                    
//                    Text("キャッチフレーズ: \(shop.shopCatch)")
//                        .font(.body)
//                        .foregroundColor(.gray)
//                    
//                    Link("店舗ページを見る", destination: URL(string: shop.urls.pc)!)
//                        .font(.headline)
//                        .foregroundColor(.blue)
//                }
//                .padding()
//            }
//        }
//        .navigationTitle("詳細情報")
//        .navigationBarTitleDisplayMode(.inline)
//    }
//}
//
//#Preview {
//    RestaurantListView()
//}
//
