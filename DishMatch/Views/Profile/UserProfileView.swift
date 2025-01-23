//
//  UserProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct UserProfileView: View {
    var body: some View {
        NavigationStack {
            List {
                UserProfileHeaderView()
            }
        }
    }
}

#Preview {
    UserProfileView()
}
