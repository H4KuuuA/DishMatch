//
//  ProfileDismissButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct ProfileDismissButtonView: View {
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "arrow.down")
                .foregroundColor(.white)
                .font(.title)
                .fontWeight(.heavy)
                .foregroundStyle(.gray)
                .background {
                    Circle()
                        .fill(.orange)
                        .frame(width: 48, height: 48)
                        .shadow(radius: 6)
                }
        }
    }
}

#Preview {
    ProfileDismissButtonView()
}
