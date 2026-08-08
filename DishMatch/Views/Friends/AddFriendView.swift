//
//  AddFriendView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 友達を追加する画面。
/// サーバーがまだ無いため、実際に相手のアカウントとやり取りすることはできない。
/// 将来の「IDで友達を追加する」体験に近づけるため、自分のIDを共有する導線と
/// 相手のIDを入力する導線を用意し、入力されたIDで仮の友達エントリを作成する形にしている。
/// 名前やアイコンは相手本人が登録するものであり自分で代入すべきではないため入力欄を設けず、
/// サーバー対応後に相手の実データへ自動で置き換わるまではIDをそのまま表示名として使う。
struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendsViewModel: FriendsViewModel
    @ObservedObject private var userProfile = UserProfile.shared
    @ObservedObject private var genreCatalog = GenreCatalog.shared
    @StateObject private var errorQueue = ErrorQueue()

    @State private var enteredCode: String = ""
    @State private var selectedGenreCodes: Set<String> = []

    /// サーバー対応までの仮のアイコン。相手本人の情報が同期されるまでの共通プレースホルダー
    private static let placeholderAvatarEmoji = "🙂"

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(userProfile.myFriendCode)
                            .font(.title2.monospaced())
                            .fontWeight(.bold)
                            .foregroundStyle(Color("FC"))
                        Spacer()
                        ShareLink(item: "DishMatchで友達になりましょう！\n私のID: \(userProfile.myFriendCode)") {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                } header: {
                    Text("自分のIDを共有する")
                } footer: {
                    Text("このIDを友達に伝えると、友達もあなたを追加できます。")
                }

                Section {
                    TextField("例）ABC12345", text: $enteredCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                } header: {
                    Text("友達のIDを入力")
                } footer: {
                    Text("現在はサーバー連携前のため、IDを入力すると仮の友達として登録されます。名前やアイコンは、サーバー対応後に相手が実際に登録した情報へ自動で置き換わります。")
                }

                Section {
                    if genreCatalog.isLoading && genreCatalog.genres.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
                            ForEach(genreCatalog.genres) { genre in
                                genreChip(genre)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("好きなジャンル")
                } footer: {
                    Text("この友達が好きそうなジャンルを選んでください。同じジャンルのお店を自分がLikeすると、マッチが成立します。")
                }
            }
            .overlay(alignment: .top) {
                ErrorBannerView(errorQueue: errorQueue)
                    .padding(.top, 8)
            }
            .navigationTitle("友達を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") { save() }
                        .fontWeight(.semibold)
                        .disabled(enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                genreCatalog.loadIfNeeded()
            }
            .onChange(of: genreCatalog.lastError) { _, newValue in
                if let newValue {
                    errorQueue.report(newValue)
                }
            }
        }
    }

    private func genreChip(_ genre: GenreOption) -> some View {
        let isSelected = selectedGenreCodes.contains(genre.code)
        return Button {
            toggle(genre)
        } label: {
            Text(genre.name)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .background(isSelected ? Color.orange : Color.gray.opacity(0.15))
                .foregroundStyle(isSelected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ genre: GenreOption) {
        if selectedGenreCodes.contains(genre.code) {
            selectedGenreCodes.remove(genre.code)
        } else {
            selectedGenreCodes.insert(genre.code)
        }
    }

    private func save() {
        let trimmedCode = enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmedCode.isEmpty else { return }
        Task {
            await friendsViewModel.addFriend(id: trimmedCode, name: trimmedCode, avatarEmoji: Self.placeholderAvatarEmoji, likedGenreCodes: selectedGenreCodes)
        }
        dismiss()
    }
}

#Preview {
    AddFriendView(friendsViewModel: FriendsViewModel())
}
