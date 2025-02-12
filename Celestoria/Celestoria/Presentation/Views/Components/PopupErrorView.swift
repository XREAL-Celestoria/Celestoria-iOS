//
//  PopupErrorView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/29/25.
//

import SwiftUI

struct PopupErrorView: View {
    let title: String
    let notes: String
    let trailingButtonText: String
    
    let circularAction: () -> Void
    let buttonAction : () -> Void
    
    let buttonImageString : String
    
    var body: some View {
        RoundedRectangle(cornerRadius: 44)
            .fill(LinearGradient.BackgroundPopup)
            .frame(width: 644, height: 324)
            .blur(radius: 100)
            .background(Color.NebulaBlack.cornerRadius(44))
            .overlay(
                RoundedRectangle(cornerRadius: 44)
                    .stroke(LinearGradient.StrokePopup, lineWidth: 3)
            )
            .shadow(color: Color(hex: "6BBAFF").opacity(0.3), radius: 30)
            .overlay(
                VStack(alignment: .leading) {
                    HStack {
                        Text(title)
                            .font(.system(size: 29, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                            .padding(.leading, 52)
                            .padding(.top, 48)
                        
                        Spacer()
                        
                        CircularButton(action: circularAction, buttonImageString: buttonImageString)
                            .padding(.trailing, 52)
                            .padding(.top, 48)
                    }
                    
                    Text(notes)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.NebulaWhite)
                        .padding(.top, 8)
                        .padding(.horizontal, 52)
                    
                    Spacer()
                    
                    Button(action: buttonAction) {
                        Text(trailingButtonText)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.NebulaBlack)
                            .frame(width: 240, height: 76)
                            .background(LinearGradient.GradientSub.cornerRadius(16))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .buttonStyle(MainButtonStyle())
                    .padding(.bottom, 0)
                }
            )
    }
}

