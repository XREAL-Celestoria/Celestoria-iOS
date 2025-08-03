//
//  iOSNavigationView.swift
//  Celestoria
//
//  Created by Seyoung Park on 8/3/25.
//

import SwiftUI

// MARK: - iOSNavigationView
struct iOSNavigationView: View {
    let title: String
    let onBack: () -> Void
    
    var body: some View {
        ZStack {
            HStack {
                Button(action: onBack) {
                    Image("backButton")
                        .resizable()
                        .frame(width: 30, height: 30)
                }
                
                Spacer()
            }
            
            HStack(alignment: .center) {
                Spacer()
                
                Text(title)
                    .fontStyle(Fonts.headline)
                    .foregroundColor(Colors.NebulaWhite)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 48)
        .padding(.horizontal, 14)
        .padding(.bottom, 20)
    }
}
