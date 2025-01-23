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
    @State private var isAllYouCanDrink: Bool = false
    @State private var isAllYouCanEat: Bool = false
    @State private var isPrivateRoomAvailable: Bool = false
    @State private var isTatamiRoomAvailable: Bool = false
    @State private var isParkingAvailable: Bool = false

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

                // その他の設定
                Section {
                    Toggle("飲み放題", isOn: $isAllYouCanDrink)
                        .tint(.orange)
                    Toggle("食べ放題", isOn: $isAllYouCanEat)
                        .tint(.orange)
                    Toggle("個室あり", isOn: $isPrivateRoomAvailable)
                        .tint(.orange)
                    Toggle("座敷", isOn: $isTatamiRoomAvailable)
                        .tint(.orange)
                    Toggle("駐車場", isOn: $isParkingAvailable)
                        .tint(.orange)
                } header: {
                    Text("こだわり")
                        .font(.headline)
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            .navigationTitle("ディスカバリー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // 完了処理：設定内容をコンソールで表示（実際は保存処理など）
                        print("距離設定: \(Int(distance)) km")
                        print("予算設定: \(Int(budget)) 円")
                        print("飲み放題: \(isAllYouCanDrink ? "有効" : "無効")")
                        print("食べ放題: \(isAllYouCanEat ? "有効" : "無効")")
                        print("個室あり: \(isPrivateRoomAvailable ? "有効" : "無効")")
                        print("座敷: \(isTatamiRoomAvailable ? "有効" : "無効")")
                        dismiss()
                    } label: {
                        Text ("完了")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    DiscoverySettingsView()
}
