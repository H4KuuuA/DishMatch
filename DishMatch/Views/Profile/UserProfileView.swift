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
                                .foregroundStyle(Color("FC"))
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
                                .foregroundStyle(Color("FC"))
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
                                .foregroundStyle(Color("FC"))
                            
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
                                .foregroundStyle(Color("FC"))
                            
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
                                .foregroundStyle(Color("FC"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section("サポート") {
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("ヘルプ・よくある質問")
                                .foregroundStyle(Color("FC"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        
                    } label: {
                        HStack {
                            Image(systemName: "text.page")
                                .foregroundStyle(.orange)
                                .padding(.trailing)
                            Text("サービス利用規約")
                                .foregroundStyle(Color("FC"))
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                Section(""){
                    HStack {
                        Text("ログアウト")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundStyle(.red.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
    }
}

#Preview {
    UserProfileView()
}
