//
//  SplashScreenView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/02/02.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.8
    @State private var opacity = 0.0

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color(Color("WB")).ignoresSafeArea()

                VStack {
                    Text("Dish")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    + Text("Match")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                .scaleEffect(scale) 
                .opacity(opacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5)) {
                        scale = 1.2
                        opacity = 1.5
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        isActive = true
                    }
                }
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
