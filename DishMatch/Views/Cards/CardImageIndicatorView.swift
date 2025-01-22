//
//  CardImageIndicatorView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct CardImageIndicatorView: View {
    let currentImageIndex: Int
    let imageCount: Int
    
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}
/// 画像の数に基づいてインジケーターの幅を調整
private extension CardImageIndicatorView {
    var imageIndicatorWidth: CGFloat {
        return SizeConstants.cardWidth * CGFloat(imageCount) - 28
    }
}

#Preview {
    CardImageIndicatorView(currentImageIndex: 1, imageCount: 3)
}

