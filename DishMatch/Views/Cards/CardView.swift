//
//  CardView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct CardView: View {
    @ObservedObject var viewModel: CardsViewModel
    
    @State private var currentImageIndex: Int = 0
    @State private var xOffset: CGFloat = 0
    @State private var degrees: Double = 0
    
    let model: CardModel
    
    var body: some View {
        ZStack (alignment: .bottom){
            ZStack (alignment: .top) {
                Image(model.store.profileImageURLs[currentImageIndex])
                    .resizable()
                    .scaledToFill()
                    .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                    .clipped()
                    .overlay {
                        ImageScrollingOverlay(currentImageIndex: $currentImageIndex, imagecount: imageCount)
                    }
                CardImageIndicatorView(currentImageIndex: currentImageIndex, imageCount: imageCount)
                SwipeActionIndicatorView(xOffset: $xOffset
                                         , screenCutOff: CGFloat(SizeConstants.screenCutOff))
            }
            StoreInfoView(store: store)
                .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight * 0.14)
                .padding(.horizontal)
        }
        .onReceive(viewModel.$buttonSwipeAction, perform: { action in
            onReceiveSwipeAction(action)
        })
        .offset(x: xOffset)
        .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .rotationEffect(.degrees(degrees))
        .animation(.snappy, value: xOffset)
        .gesture(
            DragGesture()
                .onChanged(onDragChanged)
                .onEnded(onDragEnded)
        )
    }
}

//
private extension CardView {
    // CardModelからstoreプロパティを取り出す計算プロパティ
    var store: Store {
        return model.store
    }
    // store.profileImageURLs配列の要素数を返す計算プロパティ
    var imageCount: Int {
        return store.profileImageURLs.count
    }
}

private extension CardView {
    func returnToCenter() {
        xOffset = 0
        degrees = 0
    }
    func swipeRight() {
        withAnimation {
            xOffset = 500
            degrees = 12
        } completion: {
            viewModel.removeCard(model)
        }
    }
    func swipeLeft() {
        withAnimation {
            xOffset = -500
            degrees = -12
        } completion: {
            viewModel.removeCard(model)
        }
    }
    /// likeかrejectを受け取って、最上部のカードを適切にスワイプさせる関数
    func onReceiveSwipeAction(_ action: SwipeAction?) {
        // アクションがnilの場合、早期リターン
        guard let action else { return }
        
        let topCard = viewModel.cardModels.last
        
        if  topCard == model {
            switch action {
            case .rejetct:
                swipeLeft()
            case .like:
                swipeRight()
            }
        }
    }
}
private extension CardView {
    /// ドラッグ中の変化を処理
    func onDragChanged(_ value: _ChangedGesture<DragGesture>.Value) {
        // ドラッグの移動に応じてカードの位置と回転を更新
        xOffset = value.translation.width
        degrees = Double(value.translation.width / 25)
    }
    
    /// ドラッグ終了時の処理
    func onDragEnded (_ value: _ChangedGesture<DragGesture>.Value) {
        let width = value.translation.width
        
        // 画面外にはみ出さないように戻す処理
        if abs(width) <= abs(CGFloat(SizeConstants.screenCutOff)) {
            returnToCenter()
            return
        }
        if Float(width) >= SizeConstants.screenCutOff {
            swipeRight()
        }else {
            swipeLeft()
        }
    }
}

#Preview {
    CardView(viewModel: CardsViewModel(service: CardService()), model: CardModel(store: MockData.stores[0]))
}
