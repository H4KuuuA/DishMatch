//
//  LocationDemo.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

import SwiftUI

struct LocationDemoView: View {
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("現在地の情報")
                .font(.title)
            
            Text("緯度: \(locationManager.latitude)")
                .font(.body)
            
            Text("経度: \(locationManager.longitude)")
                .font(.body)
            
            Text("バックグラウンドでも位置情報が更新されます")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

#Preview {
    LocationDemoView()
}
