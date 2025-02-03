//
//  PopupView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/24/25.
//

import SwiftUI

struct PopupView: View {
    let title: String
    let notes: String
    let leadingButtonText: String?
    let trailingButtonText: String
    
    let circularAction: () -> Void
    let leadingButtonAction: (() -> Void)?
    let trailingButtonAction : () -> Void
    
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
                    
                    HStack {
                        if let leadingButtonText = leadingButtonText,
                           let leadingButtonAction = leadingButtonAction,
                           !leadingButtonText.isEmpty {
                            Button(action: leadingButtonAction) {
                                Text(leadingButtonText)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.NebulaWhite)
                                    .frame(width: 240, height: 76)
                                    .background(Color.NebulaWhite.opacity(0.1).cornerRadius(16))
                            }
                            .buttonStyle(MainButtonStyle())
                            
                            Spacer()
                                .frame(width: 24)
                        }
                        
                        Button(action: trailingButtonAction) {
                            Text(trailingButtonText)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.NebulaBlack)
                                .frame(width: leadingButtonText == nil || leadingButtonText?.isEmpty == true ? 504 : 240, height: 76)
                                .background(LinearGradient.GradientSub.cornerRadius(16))
                        }
                        .buttonStyle(MainButtonStyle())
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .padding(.horizontal, 52)
                    .padding(.bottom, 56)
                }
            )
    }
}

