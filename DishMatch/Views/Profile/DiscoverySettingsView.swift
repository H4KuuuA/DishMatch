//
//  DiscoverySettingsView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

//
//  DiscoverySettingsView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct DiscoverySettingsView: View {
    @Environment(\.dismiss) var dismiss
    // シングルトンインスタンスを @ObservedObject として利用
    @ObservedObject private var settings = DiscoverySettings.shared
    @Binding var viewID: UUID // ビュー更新用の識別子
    
    var body: some View {
        NavigationView {
            Form {
                // 距離設定
                Section {
                    HStack {
                        Text("距離")
                        Spacer()
                        Text(settings.selectedRange.range)
                            .foregroundColor(.gray)
                    }
                    Picker("距離", selection: $settings.selectedRange) {
                        ForEach(MenuRangeType.allCases, id: \.self) { rangeOption in
                            Text(rangeOption.range).tag(rangeOption)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // 予算設定
                Section {
                    Picker("予算", selection: $settings.selectedBudget) {
                        ForEach(BudgetType.allCases, id: \.self) { budget in
                            Text(budget.rawValue).tag(budget)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // その他の設定
                Section {
                    Toggle("飲み放題", isOn: $settings.isAllYouCanDrink)
                        .tint(.orange)
                    Toggle("食べ放題", isOn: $settings.isAllYouCanEat)
                        .tint(.orange)
                    Toggle("個室あり", isOn: $settings.isPrivateRoomAvailable)
                        .tint(.orange)
                    Toggle("座敷", isOn: $settings.isTatamiRoomAvailable)
                        .tint(.orange)
                    Toggle("駐車場", isOn: $settings.isParkingAvailable)
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
                        // 完了処理：設定内容をコンソールで表示
                        print("距離設定: \(settings.selectedRange.range)")
                        print("予算設定: \(settings.selectedBudget.rawValue) (\(settings.selectedBudget.budgetCode))")
                        print("飲み放題: \(settings.isAllYouCanDrink ? "有効" : "無効")")
                        print("食べ放題: \(settings.isAllYouCanEat ? "有効" : "無効")")
                        print("個室あり: \(settings.isPrivateRoomAvailable ? "有効" : "無効")")
                        print("座敷: \(settings.isTatamiRoomAvailable ? "有効" : "無効")")
                        print("駐車場: \(settings.isParkingAvailable ? "有効" : "無効")")
                        viewID = UUID() // ビューをリロード
                        dismiss()
                    } label: {
                        Text("完了")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}
#Preview {
    DiscoverySettingsView(viewID: .constant(UUID()))
}
