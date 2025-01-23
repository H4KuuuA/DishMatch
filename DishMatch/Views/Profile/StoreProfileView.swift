//
//  StoreProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct StoreProfileView: View {
    
    @State private var currentImageIndex: Int = 0
    
    let model: CardModel
    let store: Store
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    Image(store.profileImageURLs[currentImageIndex])
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: 300) // 画像のサイズ設定
                    
                    // 店舗情報
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(store.storeName)
                                .font(.title)
                                .fontWeight(.semibold)
                                .padding(.top, 15)
                            Spacer()
                        }
                        
                        Text(store.genre)
                            .font(.caption)
                        + Text(" / ")
                            .font(.caption)
                        + Text("\(store.station_name)駅")
                            .font(.caption)
                        
                        Text("店舗情報  (詳細)")
                            .fontWeight(.semibold)
                            .padding(.top, 20)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    StoreProfileView(model: CardModel(store: MockData.stores[1]), store: MockData.stores[1])
}
