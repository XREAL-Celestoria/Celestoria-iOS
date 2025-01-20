//
//  MainButton.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct MainButton: View {
    let imageName: String
    let text: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            GeometryReader { geometry in
                VStack {
                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: geometry.size.width * 1,
                            height: geometry.size.width * 1
                        )
                    Text(text)
                        .font(.system(size: 19, weight: .bold))
                }
                .foregroundColor(.NebulaWhite)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

