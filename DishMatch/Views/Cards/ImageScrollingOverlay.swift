//
//  ImageScrollingOverlay.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct ImageScrollingOverlay: View {
    @Binding var currentImageIndex: Int
    
    let imagecount: Int
    
    var body: some View {
        HStack {
            Rectangle()
                .onTapGesture {
                    updateImageImage(increment: false)
                }
            
            Rectangle()
                .onTapGesture {
                    updateImageImage(increment: true)
                }
        }
        .foregroundStyle(.white .opacity(0.01))
    }
}

private extension ImageScrollingOverlay {
    /// 画像インデックスを増加または減少させる関数
    func updateImageImage(increment: Bool) {
        if increment {
            guard currentImageIndex < imagecount - 1 else { return }
            currentImageIndex += 1
        }else {
            guard currentImageIndex > 0 else { return }
            currentImageIndex -= 1
        }
    }
}

#Preview {
    ImageScrollingOverlay(currentImageIndex: .constant(1), imagecount: 2)
}
