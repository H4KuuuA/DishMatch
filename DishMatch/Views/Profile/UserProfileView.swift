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
                
                Section("会員登録情報") {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("登録情報")
                                .foregroundStyle(.black)
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "calendar.badge.checkmark")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("予約履歴")
                                .foregroundStyle(.black)
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "mappin.and.ellipse")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("行ったお店")
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("クーポン")
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("アプリ設定")
                                .foregroundStyle(.black)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
