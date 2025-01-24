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
        ZStack {
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
                            
                            HStack {
                                Image(systemName: "fork.knife")
                                Text("\(store.genre)")
                                    
                                Text("|")
                                Image(systemName: "mappin.and.ellipse")
                                Text("\(store.station_name)")
                            }
                            .font(.caption)
                            .lineLimit(2)
                            
                            Text("店舗情報  (詳細)")
                                .fontWeight(.semibold)
                                .padding(.top, 20)
                            
                            Spacer()
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(40)
                        .offset(y: -30)
                        
                        ProfileDismissButtonView()
                            .offset(x: 145, y: -210)
                    }
                }
            }
            // ReserveButtonViewは常に画面下部に固定
            VStack {
                Spacer()
                ReserveButtonView()
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

#Preview {
    StoreProfileView(model: CardModel(store: MockData.stores[1]), store: MockData.stores[1])
}
