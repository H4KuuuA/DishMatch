//
//  CustomTabBarView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/05.
//

import SwiftUI

/// Instagram風にアイコンのみ・ラベルなしで構成したカスタムタブバー。
/// 見た目はLiquid Glass（iOS 26+は本物のglassEffect、それ未満はMaterialで疑似再現）。
struct CustomTabBarView: View {
    @Binding var selectedTab: AppTab
    @Namespace private var glassNamespace

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                GlassEffectContainer(spacing: 24) {
                    tabBarBody
                }
            } else {
                tabBarBody
            }
        }
        .padding(.horizontal, 44)
        .padding(.bottom, 2)
    }

    private var tabBarBody: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(6)
        .liquidGlassBackground(in: Capsule())
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            guard !isSelected else { return }
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            Image(systemName: isSelected ? tab.filledSymbol : tab.outlineSymbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(isSelected ? Color(.orange) : Color.gray)
                .symbolEffect(.bounce, value: isSelected)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .contentShape(Rectangle())
                .background {
                    if isSelected {
                        // アイコンと同色を濃いtintで乗せるとガラス面が暗くなり
                        // アイコンと同化して見えなくなるため、無色のガラスのみにする
                        Color.clear
                            .liquidGlassBackground(in: Capsule())
                            .matchedGeometryEffect(id: "tabIndicator", in: glassNamespace)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tabAccessibilityLabel(for: tab))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func tabAccessibilityLabel(for tab: AppTab) -> String {
        switch tab {
        case .discover: return "発見"
        case .likes: return "お気に入り"
        case .friends: return "友達"
        case .profile: return "プロフィール"
        }
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        Color("BG").ignoresSafeArea()
        CustomTabBarView(selectedTab: .constant(.discover))
    }
}
