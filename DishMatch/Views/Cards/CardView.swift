//
//  CardView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct CardView: View {
    
    @State private var currentImageIndex: Int = 0
    
    let model: CardModel
    
    var body: some View {
        ZStack (alignment: .bottom){
            ZStack (alignment: .top) {
                Image(model.store.profileImageURLs[currentImageIndex])
                    .resizable()
                    .scaledToFill()
                    .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                    .clipped()
                    .overlay {
                        ImageScrollingOverlay(currentImageIndex: $currentImageIndex, imagecount: imageCount)
                    }
            }
            StoreInfoView(store: store)
                .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight * 0.14)
                .padding(.horizontal)
        }
        .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

//
private extension CardView {
    // CardModelからstoreプロパティを取り出す計算プロパティ
    var store: Store {
        return model.store
    }
    // store.profileImageURLs配列の要素数を返す計算プロパティ
    var imageCount: Int {
        return store.profileImageURLs.count
    }
}
#Preview {
    CardView(model: CardModel(store: MockData.stores[0]))
}
