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
    @State private var isShowProfileModal = false

    let shop: Shop // `CardModel` の代わりに `Shop` を直接使用

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                AsyncImage(url: URL(string: shop.photo.pc.l)) { phase in
                    switch phase {
                    case .empty:
                        // ローディング中のプレースホルダー
                        ProgressView()
                            .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                            .background(Color.gray.opacity(0.3))
                    case .success(let image):
                        // 正常に画像が取得できた場合
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                            .clipped()
                    case .failure:
                        // エラー時の代替画像
                        Image(systemName: "photo")
                            .resizable()
                            .scaledToFill()
                            .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                            .clipped()
                            .background(Color.gray.opacity(0.3))
                    @unknown default:
                        EmptyView()
                    }
                }
                    .overlay {
                        ImageScrollingOverlay(currentImageIndex: $currentImageIndex, imagecount: imageCount)
                    }
                CardImageIndicatorView(currentImageIndex: currentImageIndex, imageCount: imageCount)
                SwipeActionIndicatorView(xOffset: $xOffset, screenCutOff: CGFloat(SizeConstants.screenCutOff))
            }
            StoreInfoView(isShowProfileModal: $isShowProfileModal, shop: shop)
                .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight * 0.14)
                .padding(.horizontal)
        }
        .fullScreenCover(isPresented: $isShowProfileModal) {
            StoreProfileView(shop: shop)
        }
        .onReceive(viewModel.$buttonSwipeAction, perform: { action in
            onReceiveSwipeAction(action)
        })
        .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .offset(x: xOffset)
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
    // store.profileImageURLs配列の要素数を返す計算プロパティ
    var imageCount: Int {
        return 1 // `Shop` 構造体では1枚の画像しか持たないため固定
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
            viewModel.likeShop(shop)
            viewModel.removeShop(shop) // `removeCard` を `removeShop` に変更
        }
    }
    func swipeLeft() {
        withAnimation {
            xOffset = -500
            degrees = -12
        } completion: {
            viewModel.removeShop(shop) // `removeCard` を `removeShop` に変更
        }
    }
    /// likeかrejectを受け取って、最上部のカードを適切にスワイプさせる関数
    func onReceiveSwipeAction(_ action: SwipeAction?) {
        // アクションがnilの場合、早期リターン
        guard let action else { return }

        let topShop = viewModel.shops.last

        if topShop == shop {
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
    func onDragEnded(_ value: _ChangedGesture<DragGesture>.Value) {
        let width = value.translation.width

        // 画面外にはみ出さないように戻す処理
        if abs(width) <= abs(CGFloat(SizeConstants.screenCutOff)) {
            returnToCenter()
            return
        }
        if Float(width) >= SizeConstants.screenCutOff {
            swipeRight()
        } else {
            swipeLeft()
        }
    }
}

#Preview {
    CardView(viewModel: CardsViewModel(), shop: MockShop.mockShop) 
}
