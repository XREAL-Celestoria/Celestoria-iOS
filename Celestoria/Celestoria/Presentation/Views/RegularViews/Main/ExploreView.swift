//
//  ExploreView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI
import os

struct ExploreView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var searchText = ""
    @State private var filteredItems: [ExploreUserCardItem] = []
    
    let allItems: [ExploreUserCardItem] = [
        ExploreUserCardItem(userName: "User name", userProfileImageName: "CardUserProfileImage", memoryStars: 9, constellations: 2, imageName: "Thumbnail3"),
        ExploreUserCardItem(userName: "User name 2", userProfileImageName: "CardUserProfileImage", memoryStars: 4, constellations: 1, imageName: "Thumbnail6"),
        ExploreUserCardItem(userName: "User name 3", userProfileImageName: "CardUserProfileImage", memoryStars: 8, constellations: 2, imageName: "Thumbnail1")
    ]
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // NavigationBar
                NavigationBar(
                    title: "Explore",
                    action: {
                        appModel.activeScreen = .main
                    },
                    buttonImageString: "chevron.left"
                )
                .padding(.horizontal, 28)
                .padding(.top, 16)
                
                if filteredItems.isEmpty && searchText.isEmpty {
                    // Default Content
                    Image("AddMemoryDone")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 320, height: 320, alignment: .center)
                        .padding(.top, 64)
                    
                    Text("Explore other people’s Galaxy!")
                        .foregroundColor(Color.NebulaWhite)
                        .font(.system(size: 22, weight: .bold))
                        .padding(.top, 32)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 20) {
                            ForEach(filteredItems) { item in
                                ExploreUserCard(item: item)
                            }
                        }
                        .padding(.horizontal, 48)
                    }
                    .padding(.top, 44)
                }
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .bottomOrnament) {
                    ZStack {
                        // Toolbar Background
                        RoundedRectangle(cornerRadius: 42)
                            .fill(LinearGradient.GradientMain)
                            .frame(width: 920, height: 84)
                        
                        HStack {
                            // Search Bar Background
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(Color.NebulaBlack)
                                    .frame(width: 832, height: 56)
                                    .padding(.leading, 16)
                                
                                HStack {
                                    Image("Explore")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 24, height: 24)
                                        .padding(.leading, 36)
                                    
                                    TextField("Search user name", text: $searchText)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16))
                                        .onChange(of: searchText) { _ in
                                            filterItems()
                                        }
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                searchText = ""
                                filterItems()
                            }) {
                                Image("Close")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 24, height: 24)
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 44, height: 44)
                            .buttonStyle(.plain)
                            .padding(.trailing, 20)
                        }
                    }
                    .padding(.horizontal, -16)
                    .padding(.vertical, -16)
                }
            }
        }
        .onAppear {
            filterItems()
        }
    }
    
    func filterItems() {
        if searchText.isEmpty {
            filteredItems = []
        } else {
            filteredItems = allItems.filter { $0.userName.lowercased().contains(searchText.lowercased()) }
        }
    }
}

struct ExploreUserCard: View {
    let item: ExploreUserCardItem

    var body: some View {
        VStack {
            Spacer()
                .frame(height: 16)
            
            ZStack {
                Image(item.imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 400, height: 420)
                    .cornerRadius(16)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(width: 400, height: 100)
                .cornerRadius(16)
                .padding(.top, 320)
                
                VStack {
                    HStack {
                        Image(item.userProfileImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                        
                        Text(item.userName)
                            .font(.system(size: 19, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                            .padding(.leading, 12)
                        
                        Spacer()
                    }
                    .padding(.leading, 28)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    Text("\(item.memoryStars) Memory Stars, \(item.constellations) Constellations")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.NebulaWhite)
                        .padding(.bottom, 24)
                        .frame(alignment: .center)
                }
            }
    
            Spacer()
                .frame(height: 16)
            
            MainButton(
                title: "Explore Galaxy", action: {
                    os.Logger.info("Go to \(item.userName)'s Galaxy!")
                },
                isEnabled: true
            )
            
            Spacer()
                .frame(height: 16)
        }
        .frame(width: 432, height: 532)
        .background(LinearGradient.GradientCard)
        .cornerRadius(16)
    }
}
