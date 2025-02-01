//
//  APIKeyDisplayTestView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

//import SwiftUI
//
//struct APIKeyDisplayView: View {
//    @State private var apiKey: String? = nil
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let apiKey {
//                    Text("API Key: \(apiKey)")
//                        .font(.headline)
//                        .padding()
//                        .foregroundColor(.green)
//                } else {
//                    Text("API Key could not be loaded.")
//                        .font(.headline)
//                        .padding()
//                        .foregroundColor(.red)
//                }
//                Spacer()
//            }
//            .navigationTitle("API Key Viewer")
//            .onAppear {
//                loadAPIKey()
//            }
//        }
//    }
//
//    private func loadAPIKey() {
//        let keyManager = KeyManager()
//        apiKey = keyManager.getValue(forKey: "apiKey")
//    }
//}
//
//#Preview {
//    APIKeyDisplayView()
//}

