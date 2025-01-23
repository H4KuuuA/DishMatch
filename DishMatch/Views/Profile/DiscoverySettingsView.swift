//
//  DiscoverySettingsView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct DiscoverySettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var distance: Double = 5
    @State private var budget: Double = 2000
    let numbers = Array(1...100) // 1から100の数字

    var body: some View {
        NavigationView {
            Form {
                // 距離設定
                Section {
                    HStack {
                        Text("距離")
                        Spacer()
                        Text("\(Int(distance)) km")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $distance, in: 1...50, step: 1)
                        .tint(.orange)
                }
                // 予算
                Section {
                    HStack {
                        Text("予算")
                        Spacer()
                        Text("\(Int(budget)) 円")
                            .foregroundColor(.gray)
                    }
                    Slider(value: $budget, in: 500...50000, step: 100)
                        .tint(.orange)
                }
            }
            .navigationTitle("ディスカバリー設定")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DiscoverySettingsView()
}
