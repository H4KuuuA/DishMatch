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

    let shop: Shop

    var body: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                AsyncImage(url: URL(string: shop.photo.pc.l)) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                            .background(Color.gray.opacity(0.3))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: SizeConstants.cardWidth, height: SizeConstants.cardHeight)
                            .clipped()
                    case .failure:
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

private extension CardView {
    var imageCount: Int {
        return 1
    }
}
private extension CardView {
    func returnToCenter() {
        xOffset = 0
        degrees = 0
    }
    /// Like
    func swipeRight() {
        withAnimation {
            xOffset = 500
            degrees = 12
        } completion: {
            viewModel.likeShop(shop) // 親から渡されたViewModelに追加
            viewModel.removeShop(shop)
        }
    }
    /// None
    func swipeLeft() {
        withAnimation {
            xOffset = -500
            degrees = -12
        } completion: {
            viewModel.removeShop(shop)
        }
    }

    func onReceiveSwipeAction(_ action: SwipeAction?) {
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

    func onDragChanged(_ value: _ChangedGesture<DragGesture>.Value) {
        xOffset = value.translation.width
        degrees = Double(value.translation.width / 25)
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
    let viewModel = CardsViewModel() // 一貫したインスタンスを利用
    viewModel.shops = [MockShop.mockShop] // モックデータを追加
    return CardView(viewModel: viewModel, shop: MockShop.mockShop)
}

