//
//  ChatSummariesViewModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/10.
//

import Foundation

/// 友達一覧（インスタDM風）で各友達の最終メッセージを表示するためのストア。
/// 自分が参加する全会話のプレビュー（`lastMessageText`/`lastMessageAt`）を1リスナーで購読する。
@MainActor
final class ChatSummariesViewModel: ObservableObject {
    /// chatId をキーにした会話プレビュー。
    @Published private(set) var summaries: [String: ChatSummary] = [:]

    private let repository = ChatRepository()
    /// deinit（nonisolated）から解除するため nonisolated(unsafe) で宣言する。
    nonisolated(unsafe) private var token: RepositoryToken?
    private var boundUid: String?

    /// 指定uidの会話プレビュー購読を開始する（uidが変わった時だけ張り直す）。
    func bind(myUid: String) {
        guard boundUid != myUid else { return }
        token?.cancel()
        boundUid = myUid
        token = repository.observeChatSummaries(myUid: myUid) { [weak self] summaries in
            Task { @MainActor in self?.summaries = summaries }
        }
    }

    deinit { token?.cancel() }

    /// 指定した友達との最終メッセージ。まだ会話が無ければ nil。
    func summary(forFriendID friendID: String, myUid: String) -> ChatSummary? {
        summaries[ChatRepository.chatId(myUid, friendID)]
    }
}
