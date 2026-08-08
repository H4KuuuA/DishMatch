//
//  EditUserProfileView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import SwiftUI
import PhotosUI

/// ニックネーム・自己紹介・アイコン写真を編集する画面。保存内容はUserProfile経由でUserDefaultsに永続化される。
struct EditUserProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var userProfile = UserProfile.shared

    @State private var nickname: String = ""
    @State private var bio: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    /// PhotosPickerで選択直後、保存ボタンを押すまでの一時的な画像データ
    @State private var pendingAvatarData: Data?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            avatarPreview
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("ニックネーム") {
                    TextField("ニックネームを入力", text: $nickname)
                }
                Section("自己紹介") {
                    TextField("好きな食べ物や気分などを一言", text: $bio, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("登録情報")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                nickname = userProfile.nickname
                bio = userProfile.bio
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let newItem, let data = try? await newItem.loadTransferable(type: Data.self) else { return }
                    pendingAvatarData = AvatarImageResizer.resizedJPEGData(from: data)
                }
            }
        }
    }

    private var avatarPreview: some View {
        ZStack(alignment: .bottomTrailing) {
            avatarImage
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.orange.opacity(0.3), lineWidth: 2))

            Image(systemName: "camera.fill")
                .font(.caption)
                .foregroundStyle(.white)
                .padding(6)
                .background(Color.orange, in: Circle())
        }
    }

    private var avatarImage: Image {
        if let pendingAvatarData, let uiImage = UIImage(data: pendingAvatarData) {
            return Image(uiImage: uiImage)
        } else if let existingData = userProfile.avatarImageData, let uiImage = UIImage(data: existingData) {
            return Image(uiImage: uiImage)
        } else {
            return Image("UserProfileImage")
        }
    }

    private func save() {
        let trimmedNickname = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        userProfile.nickname = trimmedNickname.isEmpty ? userProfile.nickname : trimmedNickname
        userProfile.bio = bio.trimmingCharacters(in: .whitespacesAndNewlines)
        if let pendingAvatarData {
            userProfile.avatarImageData = pendingAvatarData
        }
        dismiss()
    }
}

#Preview {
    EditUserProfileView()
}
