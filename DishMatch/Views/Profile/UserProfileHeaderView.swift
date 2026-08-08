//
//  UserProfileHeaderView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct UserProfileHeaderView: View {
    @ObservedObject private var userProfile = UserProfile.shared
    @State private var isShowEditProfile = false

    var body: some View {
        VStack {
            ZStack (alignment: .topTrailing){
                avatarImage
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
                
                Button {
                    isShowEditProfile = true
                } label: {
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
            Text(userProfile.nickname)
                .foregroundStyle(Color("FC"))
                .font(.title2)
                .fontWeight(.bold)

            if !userProfile.bio.isEmpty {
                Text(userProfile.bio)
                    .foregroundStyle(.gray)
                    .font(.subheadline)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 240)
        .sheet(isPresented: $isShowEditProfile) {
            EditUserProfileView()
        }
    }

    private var avatarImage: Image {
        if let data = userProfile.avatarImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
        } else {
            Image("UserProfileImage")
        }
    }
}

#Preview {
    UserProfileHeaderView()
}
