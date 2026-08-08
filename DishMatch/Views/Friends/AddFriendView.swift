//
//  AddFriendView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 友達を追加する画面。
/// LINEのように「自分のQR/IDを見せる」または「相手のIDを入力して申請を送る」ことで
/// 双方向の友達関係を結ぶ。相手が承認すると、お互いの友達一覧に追加される。
struct AddFriendView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var friendsViewModel: FriendsViewModel
    @ObservedObject private var userProfile = UserProfile.shared

    @State private var enteredCode: String = ""
    @State private var isSending = false
    @State private var infoMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                myCodeSection
                addByCodeSection
            }
            .navigationTitle("友達を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
            }
            .alert("お知らせ", isPresented: .constant(infoMessage != nil), presenting: infoMessage) { _ in
                Button("OK") { infoMessage = nil }
            } message: { message in
                Text(message)
            }
        }
    }

    /// 自分のQRコードとIDを見せて、相手に追加してもらうためのセクション。
    private var myCodeSection: some View {
        Section {
            VStack(spacing: 16) {
                QRCodeView(text: userProfile.myFriendCode)
                    .frame(width: 180, height: 180)

                HStack(spacing: 8) {
                    Text(userProfile.myFriendCode)
                        .font(.title2.monospaced())
                        .fontWeight(.bold)
                        .foregroundStyle(Color("FC"))
                    ShareLink(item: "DishMatchで友達になりましょう！\n私のID: \(userProfile.myFriendCode)") {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        } header: {
            Text("自分のID")
        } footer: {
            Text("このQRコードまたはIDを友達に伝えると、友達があなたに申請を送れます。")
        }
    }

    /// 相手のIDを入力して友達申請を送るセクション。
    private var addByCodeSection: some View {
        Section {
            TextField("例）ABC12345", text: $enteredCode)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()

            Button {
                sendRequest()
            } label: {
                HStack {
                    Spacer()
                    if isSending {
                        ProgressView()
                    } else {
                        Text("申請を送る").fontWeight(.semibold)
                    }
                    Spacer()
                }
            }
            .disabled(isSending || enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        } header: {
            Text("友達のIDで申請")
        } footer: {
            Text("相手のIDを入力して申請を送ります。相手が承認すると、お互いの友達一覧に追加されます。")
        }
    }

    private func sendRequest() {
        let code = enteredCode
        isSending = true
        Task {
            let success = await friendsViewModel.sendFriendRequest(toCode: code)
            isSending = false
            if success {
                enteredCode = ""
                infoMessage = "友達申請を送りました。相手が承認するのを待ちましょう。"
            } else if let error = friendsViewModel.lastError {
                // 失敗理由は lastError に入っているのでそれを見せる
                infoMessage = error.message
            }
        }
    }
}

#Preview {
    AddFriendView(friendsViewModel: FriendsViewModel())
}
