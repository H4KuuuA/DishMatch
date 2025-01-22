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
            Image(model.store.profileImageURLs[currentImageIndex])
        }
    }
}

#Preview {
    CardView(model: CardModel(store: MockData.stores[0]))
}
