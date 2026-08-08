//
//  AppSettingsView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import SwiftUI

/// アプリ全体の設定画面。外観モード（ライト/ダーク）の切り替えを提供する。
struct AppSettingsView: View {
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("外観", selection: $appearanceMode) {
                        ForEach(AppearanceMode.allCases) { mode in
                            Text(mode.label).tag(mode)
                        }
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("外観モード")
                } footer: {
                    Text("アプリ内の表示テーマを切り替えます。「端末の設定に合わせる」を選ぶとiOS本体のダークモード設定に自動で追従します。")
                }
            }
            .navigationTitle("アプリ設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    AppSettingsView()
}
