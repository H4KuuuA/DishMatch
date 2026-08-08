//
//  ChatViewModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation

/// 友達1人との1対1チャットの状態を管理する。メッセージのリアルタイム購読と送信を担う。
@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []
    @Published var lastError: AppError?

    let friend: Friend
    let myUid: String

    private let chatId: String
    private let repository: ChatRepository
    /// deinit（nonisolated）から解除するため nonisolated(unsafe)。
    nonisolated(unsafe) private var token: RepositoryToken?

    /// - Parameter previewMessages: プレビュー／表示確認用の固定メッセージ。指定時は
    ///   Firestore への接続（ensureChat・購読）を行わず、この値をそのまま表示する。
    init(friend: Friend, myUid: String, repository: ChatRepository = ChatRepository(), previewMessages: [ChatMessage]? = nil) {
        self.friend = friend
        self.myUid = myUid
        self.chatId = ChatRepository.chatId(myUid, friend.id)
        self.repository = repository

        if let previewMessages {
            self.messages = previewMessages
            return
        }

        // メッセージ送信のルールが参照する会話メタ（participants）を先に用意する
        Task {
            do {
                try await repository.ensureChat(chatId: chatId, participants: [myUid, friend.id])
            } catch {
                print("DEBUG: チャットの準備エラー \(error.localizedDescription)")
            }
        }

        token = repository.observeMessages(chatId: chatId) { [weak self] messages in
            Task { @MainActor in self?.messages = messages }
        }
    }

    deinit {
        token?.cancel()
    }

    /// 自分が送ったメッセージかどうか。吹き出しの左右振り分けに使う。
    func isMine(_ message: ChatMessage) -> Bool {
        message.senderUid == myUid
    }

    func sendText(_ rawText: String) {
        let text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        Task {
            do {
                try await repository.sendText(chatId: chatId, senderUid: myUid, text: text)
            } catch {
                print("DEBUG: メッセージ送信エラー \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: "メッセージを送信できませんでした")
            }
        }
    }

    func shareShop(_ shop: Shop) {
        Task {
            do {
                try await repository.sendShop(chatId: chatId, senderUid: myUid, shop: shop)
            } catch {
                print("DEBUG: お店の共有エラー \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: "お店を共有できませんでした")
            }
        }
    }
}
