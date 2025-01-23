//
//  CardsViewModel.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import Foundation

@MainActor
class CardsViewModel: ObservableObject {
    @Published var cardModels = [CardModel]()
    // SwipeAction型で、カードのスワイプ操作「いいね」や「拒否」の状態を保持する
    @Published var buttonSwipeAction: SwipeAction?
    
    private let service: CardService
    // 一時的に削除されたカードを保存する配列
    private var removedCards: [CardModel] = []
    // removedCardsに保存する最大数
    private let maxRemovedCardsCount = 5
    
    init(service: CardService) {
        self.service = service
        Task {
            await fetchCardModels()
        }
    }
    
    // カードのデータを取得する
    func fetchCardModels() async {
        do {
            self.cardModels = try await service.fetchCardModels()
        } catch {
            print("DEBUG: fetchCardModels error \(error)")
        }
    }
    /// 指定されたカードをcardModelsから削除し、removedCardsに保存する
    func removeCard(_ card: CardModel) {
        guard let index = cardModels.firstIndex(where: { $0.id == card.id }) else { return }
        // カードを削除し、removedCardsに追加
        let removedCard = cardModels.remove(at: index)
        removedCards.append(removedCard)
        // removedCardsがmaxRemovedCardsCountを超えた場合、最古のカードを削除
        if removedCards.count > maxRemovedCardsCount {
            removedCards.removeFirst()
        }
        print("DEBUG: Removed card with storeName: \(removedCard.store.storeName)")
    }
    /// BackCardボタンが押された時に、removedCardsの最後のカードを元のcardModelsに戻す
    func restoreLastRemovedCard() {
        guard let lastRemovedCard = removedCards.last else { return }
        removedCards.removeLast()
        cardModels.insert(lastRemovedCard, at: 0)
    }
}
