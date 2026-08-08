//
//  ChatMessage.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation

/// 友達との1対1チャットのメッセージ1件。テキスト、または「いいねしたお店」の共有を表す。
/// Firestore の `chats/{chatId}/messages/{messageId}` に保存する。
struct ChatMessage: Identifiable, Codable, Equatable {
    var id: String
    /// 送信者のuid
    let senderUid: String
    /// メッセージ種別
    var kind: Kind
    /// テキストメッセージの本文（kind == .text のとき）
    var text: String?
    /// 共有されたお店（kind == .shop のとき）
    var shop: Shop?
    /// 送信時刻（timeIntervalSince1970）。並び順に使う
    var createdAt: Double

    enum Kind: String, Codable {
        case text
        case shop
    }

    /// 会話一覧のプレビュー用テキスト。
    var previewText: String {
        switch kind {
        case .text: return text ?? ""
        case .shop: return "🍽️ \(shop?.name ?? "お店")を共有しました"
        }
    }
}
