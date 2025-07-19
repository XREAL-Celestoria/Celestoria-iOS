//
//  iOSNavigationBar.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
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
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.NebulaWhite)
                    .frame(width: 32, height: 32)
                    .background(Color(hex: "E7E7E7").opacity(0.2))
                    .clipShape(Circle())
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.leading, 12)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}