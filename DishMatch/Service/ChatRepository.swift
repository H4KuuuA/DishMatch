//
//  ChatRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// 友達との1対1チャット（`chats/{chatId}` とその `messages` サブコレクション）を扱うリポジトリ。
/// chatId は2人のuidをソートして結合するため、どちらから開いても同じ会話に着地する。
final class ChatRepository: @unchecked Sendable {
    private let db = Firestore.firestore()

    /// 2人のuidから一意な chatId を作る（順序に依存しない）。
    static func chatId(_ a: String, _ b: String) -> String {
        [a, b].sorted().joined(separator: "__")
    }

    private func chatDocument(_ chatId: String) -> DocumentReference {
        db.collection("chats").document(chatId)
    }

    private func messagesCollection(_ chatId: String) -> CollectionReference {
        chatDocument(chatId).collection("messages")
    }

    /// チャットのメタドキュメント（participants）が無ければ作成する。
    /// メッセージ送信のセキュリティルールが participants を参照するため、送信前に必ず呼ぶ。
    func ensureChat(chatId: String, participants: [String]) async throws {
        try await chatDocument(chatId).setData(["participants": participants], merge: true)
    }

    /// 自分が参加する全会話の最終メッセージ（プレビュー）をリアルタイム購読する。
    /// 友達一覧をインスタDM風に表示するために使う。chatId をキーに返す。
    /// participants の read ルールに合致するため `arrayContains` クエリで安全に取得できる。
    func observeChatSummaries(myUid: String, onChange: @escaping @Sendable ([String: ChatSummary]) -> Void) -> RepositoryToken? {
        let registration = db.collection("chats")
            .whereField("participants", arrayContains: myUid)
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                var summaries: [String: ChatSummary] = [:]
                for document in documents {
                    let data = document.data()
                    summaries[document.documentID] = ChatSummary(
                        lastMessageText: data["lastMessageText"] as? String,
                        lastMessageAt: data["lastMessageAt"] as? Double
                    )
                }
                onChange(summaries)
            }
        return FirestoreListenerToken(registration: registration)
    }

    /// メッセージを送信時刻順にリアルタイム購読する。
    func observeMessages(chatId: String, onChange: @escaping @Sendable ([ChatMessage]) -> Void) -> RepositoryToken? {
        let registration = messagesCollection(chatId)
            .order(by: "createdAt")
            .addSnapshotListener { snapshot, _ in
                guard let documents = snapshot?.documents else { return }
                let messages = documents.compactMap { try? $0.data(as: ChatMessage.self) }
                onChange(messages)
            }
        return FirestoreListenerToken(registration: registration)
    }

    /// テキストメッセージを送信する。
    func sendText(chatId: String, senderUid: String, text: String) async throws {
        let message = ChatMessage(
            id: "",
            senderUid: senderUid,
            kind: .text,
            text: text,
            shop: nil,
            createdAt: Date().timeIntervalSince1970
        )
        try await send(message, chatId: chatId)
    }

    /// お店の共有メッセージを送信する。
    func sendShop(chatId: String, senderUid: String, shop: Shop) async throws {
        let message = ChatMessage(
            id: "",
            senderUid: senderUid,
            kind: .shop,
            text: nil,
            shop: shop,
            createdAt: Date().timeIntervalSince1970
        )
        try await send(message, chatId: chatId)
    }

    /// メッセージをサブコレクションに追加し、会話のプレビュー（最終メッセージ）を更新する。
    private func send(_ message: ChatMessage, chatId: String) async throws {
        let document = messagesCollection(chatId).document()
        var stored = message
        stored.id = document.documentID
        try document.setData(from: stored)

        // 会話一覧のプレビュー用に最終メッセージを保存（失敗しても本文送信は成立させる）
        try? await chatDocument(chatId).setData([
            "lastMessageText": stored.previewText,
            "lastMessageAt": stored.createdAt
        ], merge: true)
    }
}
