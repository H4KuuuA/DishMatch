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
            ZStack (alignment: .topTrailing){
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
                
                Button(action: {}) {
                    Image(systemName: "pencil")
                        .imageScale(.small)
                        .foregroundStyle(.gray)
                        .background {
                            Circle()
                                .fill(Color("BG"))
                                .frame(width: 32, height: 32)
                        }
                    
                }
                .offset(x: -8, y: 10)
                
            }
            .padding()
            Text("ご飯探検隊")
                .foregroundStyle(Color("FC"))
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
