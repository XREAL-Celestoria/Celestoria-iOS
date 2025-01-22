//
//  CategoryButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/23/25.
//

import SwiftUI

// MARK: - Category Button
struct CategoryButton: View {
    let title: String
    let icon: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(.white)
            Text(title)
                .foregroundColor(.white)
                .font(.caption)
        }
        .padding()
        .background(Color.gray.opacity(0.2).cornerRadius(10))
    }
}
