//
//  ChatView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// 友達1人との1対1チャット画面。テキストのやり取りに加え、
/// いいねしたお店を共有できる（仕様書の「好みのお店を友達と共有」に対応）。
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    /// お店共有ピッカー用に、自分のいいねしたお店を参照する
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    /// チャット表示中はタブバーを隠して画面いっぱいに使う
    @EnvironmentObject private var tabBarVisibility: TabBarVisibility

    @State private var draft = ""
    @State private var isShowShopPicker = false
    /// お店バブルをタップした時に詳細表示するお店
    @State private var shopToShow: Shop?

    init(friend: Friend, myUid: String, restaurantViewModel: RestaurantViewModel, previewMessages: [ChatMessage]? = nil) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(friend: friend, myUid: myUid, previewMessages: previewMessages))
        self.restaurantViewModel = restaurantViewModel
    }

    var body: some View {
        VStack(spacing: 0) {
            messagesList
            Divider()
            inputBar
        }
        .navigationTitle(viewModel.friend.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isShowShopPicker) {
            shopPicker
        }
        .fullScreenCover(item: $shopToShow) { shop in
            StoreProfileView(shop: shop)
        }
        .alert(item: $viewModel.lastError) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
        // チャット表示中はタブバーを隠し、離れたら元に戻す
        .onAppear { tabBarVisibility.isHidden = true }
        .onDisappear { tabBarVisibility.isHidden = false }
    }

    // MARK: - メッセージ一覧

    private var messagesList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if viewModel.messages.isEmpty {
                        emptyState
                    }
                    ForEach(viewModel.messages) { message in
                        bubble(message).id(message.id)
                    }
                    // 自動スクロールの着地点
                    Color.clear.frame(height: 1).id(bottomAnchorID)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages) { _, _ in
                withAnimation { proxy.scrollTo(bottomAnchorID, anchor: .bottom) }
            }
            .onAppear {
                proxy.scrollTo(bottomAnchorID, anchor: .bottom)
            }
        }
    }

    private let bottomAnchorID = "chat-bottom-anchor"

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("メッセージを送ってみましょう")
                .font(.subheadline)
                .foregroundStyle(.gray)
            Text("下の🍽️ボタンから、いいねしたお店を共有できます。")
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    @ViewBuilder
    private func bubble(_ message: ChatMessage) -> some View {
        let mine = viewModel.isMine(message)
        HStack {
            if mine { Spacer(minLength: 48) }

            switch message.kind {
            case .text:
                textBubble(message.text ?? "", mine: mine)
            case .shop:
                if let shop = message.shop {
                    shopBubble(shop, mine: mine)
                }
            }

            if !mine { Spacer(minLength: 48) }
        }
    }

    private func textBubble(_ text: String, mine: Bool) -> some View {
        Text(text)
            .foregroundStyle(mine ? .white : Color("FC"))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(mine ? Color.orange : Color.gray.opacity(0.18), in: RoundedRectangle(cornerRadius: 18))
    }

    /// 共有されたお店のカード。タップで店舗詳細へ。
    private func shopBubble(_ shop: Shop, mine: Bool) -> some View {
        Button {
            shopToShow = shop
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                CachedShopImage(urlString: shop.photo.pc.l)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 220, height: 130)
                    .clipped()

                VStack(alignment: .leading, spacing: 2) {
                    Text(shop.name)
                        .font(.subheadline.bold())
                        .foregroundStyle(Color("FC"))
                        .lineLimit(1)
                    Text(shop.genre.name)
                        .font(.caption)
                        .foregroundStyle(.gray)
                    Text("タップして詳細を見る")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .padding(10)
            }
            .frame(width: 220)
            .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(mine ? Color.orange.opacity(0.4) : Color.gray.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 入力バー

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                isShowShopPicker = true
            } label: {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }

            TextField("メッセージを入力", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.12), in: Capsule())

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title)
                    .foregroundStyle(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .orange)
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private func send() {
        viewModel.sendText(draft)
        draft = ""
    }

    // MARK: - お店共有ピッカー

    private var shopPicker: some View {
        NavigationStack {
            Group {
                if restaurantViewModel.favoriteShops.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)
                        Text("共有できるお店がありません")
                            .font(.headline)
                        Text("お店をLikeすると、ここから友達に共有できます。")
                            .font(.subheadline)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(restaurantViewModel.favoriteShops) { shop in
                        Button {
                            viewModel.shareShop(shop)
                            isShowShopPicker = false
                        } label: {
                            HStack(spacing: 12) {
                                CachedShopImage(urlString: shop.photo.pc.l)
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 56, height: 56)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(shop.name).font(.subheadline.bold()).lineLimit(1)
                                    Text(shop.genre.name).font(.caption).foregroundStyle(.gray)
                                }
                                Spacer()
                                Image(systemName: "paperplane.fill").foregroundStyle(.orange)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .navigationTitle("お店を共有")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { isShowShopPicker = false }
                }
            }
        }
    }
}
