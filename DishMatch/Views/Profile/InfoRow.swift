//
//  StoreProfileDetailView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/26.
//

import SwiftUI

struct InfoRow: View {
    var title: String
    var detail: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color("FC"))
                .frame(width: 80, alignment: .leading)
                .padding(.trailing)
            Text(detail)
                .font(.subheadline) 
            Spacer()
        }
        .padding(.vertical, 6)
        
    }
}

#Preview {
    InfoRow(title: "住所", detail: "123 Tokyo Street")
        .padding()
}
