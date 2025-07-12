//
//  NavigationMenuPopup.swift
//  Celestoria
//
//  Created by Minjun Kim on 2/4/25.
//

import SwiftUI

struct NavigationMenuPopup: View {
    let reportAction: () -> Void
    let blockAction: () -> Void
    
    var body: some View {
        VStack(spacing: 6) {
            Button(action: reportAction) {
                HStack(spacing: 14) {
                    Image("report")
                    Text("Report Post")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.clear)
            
            Button(action: blockAction) {
                HStack(spacing: 14) {
                    Image("block")
                    Text("Block User")
                        .foregroundColor(.white)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 14)
            }
            .buttonStyle(PlainButtonStyle())
            .background(Color.clear)
        }
        .frame(width: 182, height: 104, alignment: .center)
        .background(
            LinearGradient(
                stops: [
                    .init(color: Color(red: 0.09, green: 0.09, blue: 0.09), location: 0.00),
                    .init(color: Color(red: 0.29, green: 0.29, blue: 0.29), location: 0.65),
                    .init(color: Color(red: 0.33, green: 0.77, blue: 1), location: 1.00)
                ],
                startPoint: UnitPoint(x: 0.5, y: 0),
                endPoint: UnitPoint(x: 0.5, y: 1)
            )
        )
        .cornerRadius(15.39916)
        .shadow(color: Color(red: 0.42, green: 0.73, blue: 1), radius: 5.02146, x: 0, y: 0)
        .overlay(
            RoundedRectangle(cornerRadius: 15.39916)
                .inset(by: 0.5)
                .stroke(Color.white, lineWidth: 1.00429)
        )
    }
}
