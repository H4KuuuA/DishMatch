//
//  DiscoverSettingsButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct DiscoverSettingsButtonView: View {
    @Binding var isShowDiscoverSettings: Bool
    var body: some View {
        Button {
            isShowDiscoverSettings.toggle()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .fontWeight(.heavy)
                .foregroundStyle(.gray)
                .background {
                    Circle()
                        .fill(.white)
                        .frame(width: 48, height: 48)
                        .shadow(radius: 6)
                }
                
        }
        .frame(width: 48, height: 48)
    }
}

#Preview {
    DiscoverSettingsButtonView(isShowDiscoverSettings: .constant(false))
}
