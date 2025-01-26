//
//  BackCardButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct ResetCardButtonView: View {
    @Binding var viewID: UUID // ビュー更新用の識別子

    var body: some View {
        Button {
            viewID = UUID() // ビューをリロード
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
    ResetCardButtonView(viewID: .constant(UUID()))
}


