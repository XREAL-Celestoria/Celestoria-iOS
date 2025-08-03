//
//  iOSNavigationBar.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSNavigationBar: View {
    let title: String
    let action: () -> Void
    let buttonImageString: String
    
    var body: some View {
        HStack {
            Button(action: action) {
                Image(systemName: buttonImageString)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(Colors.NebulaWhite)
                    .frame(width: 44, height: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Colors.NebulaWhite)
            
            Spacer()
            
            // Placeholder for balance
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7))
    }
}
