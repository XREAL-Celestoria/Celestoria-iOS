//
//  ExploreView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct ExploreView: View {
    var body: some View {
            NavigationStack {
                Text("Main Content")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea()) // 배경 설정
                    .toolbar {
                        ToolbarItem(placement: .bottomOrnament) {
                            Button(action: {
                                print("Home tapped")
                            }) {
                                VStack {
                                    Image(systemName: "house")
                                        .font(.system(size: 24))
                                    Text("Home")
                                        .font(.footnote)
                                }
                            }
                        }
                        ToolbarItem(placement: .bottomOrnament) {
                            Button(action: {
                                print("Search tapped")
                            }) {
                                VStack {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 24))
                                    Text("Search")
                                        .font(.footnote)
                                }
                            }
                        }
                        ToolbarItem(placement: .bottomOrnament) {
                            Button(action: {
                                print("Settings tapped")
                            }) {
                                VStack {
                                    Image(systemName: "gear")
                                        .font(.system(size: 24))
                                    Text("Settings")
                                        .font(.footnote)
                                }
                            }
                        }
                    }
            }
        }
}

#Preview {
    ExploreView()
}
