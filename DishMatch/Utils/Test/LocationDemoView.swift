////
////  LocationDemo.swift
////  DishMatch
////
////  Created by 大江悠都 on 2025/01/23.
////
//
//import SwiftUI
//
//struct LocationDemoView: View {
//    @ObservedObject private var locationManager = LocationManager.shared // シングルトンを使用
//    
//    var body: some View {
//        VStack(spacing: 20) {
//            Text("現在地の情報")
//                .font(.title)
//            
//            Text("緯度: \(locationManager.latitude, specifier: "%.6f")") // 小数点以下を指定
//                .font(.body)
//            
//            Text("経度: \(locationManager.longitude, specifier: "%.6f")") // 小数点以下を指定
//                .font(.body)
//            
//            Text("バックグラウンドでも位置情報が更新されます")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//        }
//        .padding()
//        .onAppear {
//            // 必要に応じて初期化や設定を行う
//            _ = LocationManager.shared
//        }
//    }
//}
//
//#Preview {
//    LocationDemoView()
//}
