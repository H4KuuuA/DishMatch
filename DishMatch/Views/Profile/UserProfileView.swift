//
//  UserProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject private var authService: AuthService
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @State private var isShowEditProfile = false
    @State private var isShowVisitedShops = false
    @State private var isShowAppSettings = false
    @State private var comingSoonDestination: ComingSoonDestination?
    @State private var isShowLogoutConfirmation = false
    @State private var logoutError: AppError?

    var body: some View {
        NavigationStack {
            List {
                UserProfileHeaderView()

                Section("会員登録情報") {
                    profileRow(icon: "person.fill", title: "登録情報") {
                        isShowEditProfile = true
                    }
                    profileRow(icon: "calendar.badge.checkmark", title: "予約履歴") {
                        comingSoonDestination = .reservationHistory
                    }
                    profileRow(icon: "mappin.and.ellipse", title: "行ったお店") {
                        isShowVisitedShops = true
                    }
                    profileRow(icon: "tag.fill", title: "クーポン") {
                        comingSoonDestination = .coupon
                    }
                    profileRow(icon: "gearshape.fill", title: "アプリ設定") {
                        isShowAppSettings = true
                    }
                }

                Section("サポート") {
                    profileRow(icon: "info.circle", title: "ヘルプ・よくある質問") {
                        comingSoonDestination = .help
                    }
                    profileRow(icon: "text.page", title: "サービス利用規約") {
                        comingSoonDestination = .terms
                    }
                }

                #if DEBUG
                Section("開発ツール") {
                    NavigationLink {
                        RecommendationEvalView()
                    } label: {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("AIおすすめの評価")
                                .foregroundStyle(Color("FC"))
                        }
                    }
                }
                #endif

                Section(""){
                    Button {
                        isShowLogoutConfirmation = true
                    } label: {
                        HStack {
                            Text("ログアウト")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundStyle(.red.opacity(0.8))
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                }
            }
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $isShowEditProfile) {
            EditUserProfileView()
        }
        .sheet(isPresented: $isShowVisitedShops) {
            VisitedShopsView(restaurantViewModel: restaurantViewModel)
        }
        .sheet(isPresented: $isShowAppSettings) {
            AppSettingsView()
        }
        .sheet(item: $comingSoonDestination) { destination in
            ComingSoonView(title: destination.title, systemImage: destination.systemImage, message: destination.message)
        }
        .confirmationDialog("ログアウトしますか？", isPresented: $isShowLogoutConfirmation, titleVisibility: .visible) {
            Button("ログアウト", role: .destructive) {
                do {
                    try authService.signOut()
                    // 成功時は AuthService の状態リスナーが認証画面へ切り替える
                } catch {
                    logoutError = error as? AppError ?? AppError.fromAuth(error, fallbackTitle: "ログアウトに失敗しました")
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .alert(item: $logoutError) { error in
            Alert(title: Text(error.title), message: Text(error.message), dismissButton: .default(Text("OK")))
        }
    }

    private func profileRow(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(.orange)
                    .padding(.trailing)
                Text(title)
                    .foregroundStyle(Color("FC"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
    }
}

/// 実データを持たずComingSoonViewへ遷移するだけの項目
private enum ComingSoonDestination: Identifiable {
    case reservationHistory
    case coupon
    case help
    case terms

    var id: String {
        switch self {
        case .reservationHistory: return "reservationHistory"
        case .coupon: return "coupon"
        case .help: return "help"
        case .terms: return "terms"
        }
    }

    var title: String {
        switch self {
        case .reservationHistory: return "予約履歴"
        case .coupon: return "クーポン"
        case .help: return "ヘルプ・よくある質問"
        case .terms: return "サービス利用規約"
        }
    }

    var systemImage: String {
        switch self {
        case .reservationHistory: return "calendar.badge.checkmark"
        case .coupon: return "tag.fill"
        case .help: return "info.circle"
        case .terms: return "text.page"
        }
    }

    var message: String {
        switch self {
        case .reservationHistory: return "予約履歴機能は近日対応予定です。お店との出会いをもっと形に残せるようにしていきます。"
        case .coupon: return "クーポン機能は近日対応予定です。"
        case .help: return "よくある質問は準備中です。ご不明な点があればアプリ設定からお問い合わせください。"
        case .terms: return "サービス利用規約は準備中です。"
        }
    }
}

#Preview {
    UserProfileView(restaurantViewModel: RestaurantViewModel(friendsViewModel: FriendsViewModel()))
        .environmentObject(AuthService())
}
