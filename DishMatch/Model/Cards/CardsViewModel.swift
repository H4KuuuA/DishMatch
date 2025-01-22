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
    private let service: CardService
    
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
}
