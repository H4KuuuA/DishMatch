//
//  LikesSearchView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/31.
//

import SwiftUI

struct LikesSearchView: View {
    @Binding var isPresented: Bool
    @State private var serachText: String = ""
    @State private var searcHistory : [String] = []
    @State private var keyboardOffset: CGFloat = 0
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

#Preview {
    LikesSearchView(isPresented: .constant(true))
}
