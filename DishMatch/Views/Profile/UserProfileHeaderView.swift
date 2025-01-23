//
//  UserProfileHeaderView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct UserProfileHeaderView: View {
    var body: some View {
        VStack {
            Image("UserProfileImage")
                .resizable()
                .scaledToFill()
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .background {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 128, height: 128)
                        .shadow(radius: 10)
                }
                .padding()
            Text("ご飯探検隊")
                .font(.title2)
                .fontWeight(.bold)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
    }
}

#Preview {
    UserProfileHeaderView()
}
