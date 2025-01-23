//
//  StoreInfoView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct StoreInfoView: View {
    
    @Binding var isShowProfileModal: Bool
    
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
                    isShowProfileModal.toggle()
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .fontWeight(.bold)
                        .imageScale(.large)
                }
            }
            HStack {
                Image(systemName: "fork.knife")
                Text("\(store.genre)")
                    
                Text("|")
                Image(systemName: "mappin.and.ellipse")
                Text("\(store.station_name)")
            }
            .font(.subheadline)
            .lineLimit(2)
        }
        .padding()
        .background(
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
        )
        .foregroundStyle(.white)
    }
}

#Preview {
    StoreInfoView(isShowProfileModal: .constant(false)
                  , store: MockData.stores[1])
}
