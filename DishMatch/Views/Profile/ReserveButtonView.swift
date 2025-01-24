//
//  ReserveButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct ReserveButtonView: View {
    var body: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "phone.fill")
                    .foregroundColor(.gray .opacity(0.8))
                    .frame(width: 60, height: 48)
                    .background(Color("BG"))
                    .cornerRadius(24)
            }
            Spacer()
                
            Button(action: {}) {
                    Text("ネットで予約")
                        .padding()
                        .padding(.horizontal)
                        .font(.headline)
                        .foregroundColor(Color("FC"))
                        .frame(width: 240, height: 48)
                        .background(Color.orange)
                        .cornerRadius(24)
                }
        }
        .padding(24)
        .padding(.bottom, 8)
        .background(Color("SubColor"))
        .cornerRadius(50, corners: .topLeft)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    ReserveButtonView()
}
