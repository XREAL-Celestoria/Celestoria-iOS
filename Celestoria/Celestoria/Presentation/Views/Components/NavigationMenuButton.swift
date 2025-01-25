//
//  NavigationMenuButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/26/25.
//

import Foundation
import SwiftUI

struct NavigationMenuButton: View {
    let menuItem: MenuItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 40) {
                Image(isSelected ? menuItem.imageSelected : menuItem.imageUnselected)
                    .resizable()
                    .frame(width: 40, height: 40)
                Text(menuItem.title)
                    .font(
                        .system(size: 22, weight: .semibold)
                    )
                    .foregroundStyle(
                        isSelected
                            ? LinearGradient.GradientMain
                            : LinearGradient(colors: [.white.opacity(0.6)], startPoint: .leading, endPoint: .trailing)
                    )
            }
            .padding(.leading, 10)
            .padding(.trailing, 20)
            .padding(.vertical, 12)
            .frame(maxWidth: 380, alignment: .leading)
            .background(
                isSelected
                    ? .white.opacity(0.1)
                    : .clear
            )
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}


//MARK: - Enum
struct MenuItem {
    let title: String
    let imageSelected: String
    let imageUnselected: String
}

let settingsMenuItems = [
    MenuItem(title: "Profile", imageSelected: "settings-profile-on", imageUnselected: "settings-profile-off"),
    MenuItem(title: "Thumbnail", imageSelected: "settings-thumbnail-on", imageUnselected: "settings-thumbnail-off"),
    MenuItem(title: "Account", imageSelected: "settings-account-on", imageUnselected: "settings-account-off")
]

let galaxyMenuItems = [
    MenuItem(title: "Galaxy Background", imageSelected: "galaxy-background", imageUnselected: "galaxy-background")
]
