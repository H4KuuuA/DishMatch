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
            
            Spacer()
            
            Text("NONE")
        }
        .padding(40)
    }
}

#Preview {
    SwipeActionIndicatorView()
}
