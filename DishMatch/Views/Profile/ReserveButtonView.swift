//
//  ReserveButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct ReserveButtonView: View {
    let shop: Shop
    /// 電話番号の取得は親（StoreProfileView）が1回だけ行い、ここでは結果を共有するだけにする
    @ObservedObject var placeInfo: GooglePlaceInfoViewModel
    @Environment(\.openURL) private var openURL
    @State private var isShowPhoneNumberNotFoundAlert = false

    var body: some View {
        HStack {
            phoneButton
            Spacer()

            reserveButton
        }
        .padding(24)
        .padding(.bottom, 8)
        .background(Color("SubColor"))
        .cornerRadius(50, corners: .topLeft)
        .frame(maxHeight: .infinity, alignment: .bottom)
        .alert("電話番号が見つかりませんでした", isPresented: $isShowPhoneNumberNotFoundAlert) {
            Button("お店のページを開く") {
                if let pageURL = URL(string: shop.urls.pc) {
                    openURL(pageURL)
                }
            }
            Button("閉じる", role: .cancel) {}
        } message: {
            Text("このお店の電話番号は取得できませんでした。お店のページで確認できる場合があります。")
        }
    }

    /// Google Placesで電話番号が取得できればtel:で発信し、取れなければ見つからなかった旨をアラートで伝える
    private var phoneButton: some View {
        Button {
            guard !placeInfo.isLoading else { return }
            if let phoneNumber = placeInfo.phoneNumber, let url = telURL(for: phoneNumber) {
                openURL(url)
            } else {
                isShowPhoneNumberNotFoundAlert = true
            }
        } label: {
            Group {
                if placeInfo.isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "phone.fill")
                }
            }
            .foregroundColor(.gray.opacity(0.8))
            .frame(width: 60, height: 48)
            .background(Color("BG"))
            .cornerRadius(24)
        }
    }

    /// HotPepperのAPIでは予約を直接送信できないため、予約フォームのある店舗ページを開く
    private var reserveButton: some View {
        Button {
            if let url = URL(string: shop.urls.pc) {
                openURL(url)
            }
        } label: {
            Text("ネットで予約")
                .padding()
                .padding(.horizontal)
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 240, height: 48)
                .background(Color.orange)
                .cornerRadius(24)
        }
    }

    private func telURL(for phoneNumber: String) -> URL? {
        let digits = phoneNumber.filter { $0.isNumber || $0 == "+" }
        guard !digits.isEmpty else { return nil }
        return URL(string: "tel://\(digits)")
    }
}

#Preview {
    ReserveButtonView(shop: MockShop.mockShop, placeInfo: GooglePlaceInfoViewModel())
}
