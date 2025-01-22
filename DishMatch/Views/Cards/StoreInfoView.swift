//
//  StoreInfoView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct StoreInfoView: View {
    let store: Store
    var body: some View {
        VStack (alignment: .leading){
            HStack {
                Text(store.storeName)
                    .font(.title)
                    .fontWeight(.heavy)
                
                Spacer()
                
                // プロフィール表示ボタン
                Button {
                    
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .fontWeight(.bold)
                        .imageScale(.large)
                }
            }
            HStack {
                Image(systemName: "fork.knife")
                Text("\(store.genre)")
                    .font(.subheadline)
                    .lineLimit(2)
                Text("|")
                Image(systemName: "mappin.and.ellipse")
                Text("\(store.station_name)")
            }
        }
        .padding()
        .background(
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
        )
        .foregroundStyle(.white)
    }
}

#Preview {
    StoreInfoView(store: MockData.stores[1])
}
