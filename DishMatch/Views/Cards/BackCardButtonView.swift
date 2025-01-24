//
//  BackCardButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct BackCardButtonView: View {
    
    @ObservedObject var viewModel: CardsViewModel
    
    var body: some View {
        Button {
            viewModel.restoreLastRemovedCard()
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .fontWeight(.heavy)
                .foregroundStyle(.yellow)
                .background {
                    Circle()
                        .fill(Color("BG"))
                        .frame(width: 48, height: 48)
                        .shadow(radius: 6)
                }
                
        }
        .frame(width: 48, height: 48)
    }
}

#Preview {
    BackCardButtonView(viewModel: CardsViewModel(service: CardService()))
}
