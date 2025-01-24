//
//  NavigationBar.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/22/25.
//

import SwiftUI

struct NavigationBar: View {
    let title: String
    let action: () -> Void
    let buttonImageString : String
    
    var body: some View {
        HStack {
            CircularButton(action: action, buttonImageString: buttonImageString)
            
            Text(title)
                .font(.system(size: 29, weight: .bold))
                .foregroundColor(.NebulaWhite)
                .padding(.leading, 24)
            
            Spacer()
        }
        .background(Color.clear)
        .padding(.horizontal, 28)
        .padding(.top, 28)
    }
}
