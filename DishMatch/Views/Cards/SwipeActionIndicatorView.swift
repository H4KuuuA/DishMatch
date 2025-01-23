//
//  SwipeActionIndicatorView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct SwipeActionIndicatorView: View {
    var body: some View {
        HStack {
            Text("LIKE")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.green)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: 100, height: 48)
                }
            
            Spacer()
            
            Text("NONE")
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.red)
                .overlay {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.red, lineWidth: 2)
                        .frame(width: 100, height: 48)
                }
        }
        .padding(40)
    }
}

#Preview {
    SwipeActionIndicatorView()
}
