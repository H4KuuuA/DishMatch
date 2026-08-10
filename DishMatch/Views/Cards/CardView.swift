//
//  CardView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI
import UIKit

struct CardView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel

    @State private var currentImageIndex: Int = 0
    @State private var xOffset: CGFloat = 0
    @State private var degrees: Double = 0
    @State private var isShowProfileModal = false
    /// しきい値（Like/None が確定する境界）を越えているか。越えた瞬間だけ軽い振動を出すために持つ
    @State private var didCrossThreshold = false
    /// Likeが確定した瞬間だけ表示するハート。「いいね」であって「マッチ」ではないため、
    /// フルスクリーン演出ではなくカード上でさりげなく主張する程度にとどめる
    @State private var isShowLikeBurst = false

    let shop: Shop

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                CachedShopImage(urlString: shop.photo.pc.l)
                    .scaledToFill()
                    .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                    .clipped()
                    .background(Color.gray.opacity(0.3))
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
        .overlay(alignment: .topTrailing) {
            if isShowLikeBurst {
                Image(systemName: "heart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 6)
                    .padding(20)
                    .scaleEffect(isShowLikeBurst ? 1 : 0.4)
                    .opacity(isShowLikeBurst ? 1 : 0)
                    .allowsHitTesting(false)
            }
        }
        .fullScreenCover(isPresented: $isShowProfileModal) {
            StoreProfileView(shop: shop)
        }
        .onReceive(restaurantViewModel.$selectedSwipeAction, perform: { action in
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

private extension CardView {
    var imageCount: Int {
        return 1
    }
}
private extension CardView {
    private func returnToCenter() {
        xOffset = 0
        degrees = 0
        didCrossThreshold = false
    }
    /// 指定スタイルの触覚フィードバックを鳴らす
    private func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    /// Like
    private func swipeRight() {
        playHaptic(.medium)
        triggerLikeBurst()
        withAnimation {
            xOffset = 500
            degrees = 12
        } completion: {
            restaurantViewModel.addToFavorites(shop) // 親から渡されたViewModelに追加
            restaurantViewModel.dismissShop(shop)
        }
    }

    /// カード右上にハートを一瞬だけ浮かべて消す。「マッチ」ではなく「いいね」の
    /// 軽いフィードバックなので、画面遷移や派手な演出は行わない
    private func triggerLikeBurst() {
        withAnimation(.easeOut(duration: 0.18)) {
            isShowLikeBurst = true
        }
        withAnimation(.easeIn(duration: 0.22).delay(0.18)) {
            isShowLikeBurst = false
        }
    }
    /// None
    private func swipeLeft() {
        playHaptic(.medium)
        withAnimation {
            xOffset = -500
            degrees = -12
        } completion: {
            restaurantViewModel.dismissShop(shop)
        }
    }

    private func onReceiveSwipeAction(_ action: SwipeAction?) {
        guard let action else { return }
        let topShop = restaurantViewModel.shopList.last

        if topShop == shop {
            switch action {
            case .rejetct:
                swipeLeft()
            case .like:
                swipeRight()
            }
            // アクション完了後にリセット
            DispatchQueue.main.async {
                restaurantViewModel.selectedSwipeAction = nil
            }
        }
    }

    func onDragChanged(_ value: _ChangedGesture<DragGesture>.Value) {
        xOffset = value.translation.width
        degrees = Double(value.translation.width / 25)

        // Like/None が確定するしきい値を越えた瞬間だけ軽い振動でフィードバックする
        let isPastThreshold = abs(value.translation.width) >= CGFloat(SizeConstants.screenCutOff)
        if isPastThreshold != didCrossThreshold {
            didCrossThreshold = isPastThreshold
            if isPastThreshold {
                playHaptic(.light)
            }
        }
    }

    func onDragEnded(_ value: _ChangedGesture<DragGesture>.Value) {
        let width = value.translation.width

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
    let restaurantViewModel = RestaurantViewModel(friendsViewModel: FriendsViewModel())
    restaurantViewModel.shopList = [MockShop.mockShop]

    return CardView(
        restaurantViewModel: restaurantViewModel,
        shop: MockShop.mockShop
    )
}

