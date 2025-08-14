//
//  iOSPopupView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/3/25.
//

import SwiftUI

// MARK: - Popup Style Enum
enum PopupStyle {
    case twoButtons(cancelTitle: String, confirmTitle: String, isDestructive: Bool = false)
    case singleButton(title: String)
}

// MARK: - Confirmation Popup View
struct iOSConfirmationPopupView: View {
    let title: String
    let message: String
    let style: PopupStyle
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    init(
        title: String, 
        message: String, 
        style: PopupStyle,
        onCancel: @escaping () -> Void, 
        onConfirm: @escaping () -> Void
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.onCancel = onCancel
        self.onConfirm = onConfirm
    }
    
    var body: some View {
        ZStack {
            // Background overlay with smooth opacity transition
            Color.black
                .opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Popup content with smooth opacity transition
            VStack(alignment: .leading) {
                
                Spacer()
                    .frame(height: 40)
                
                // Title
                Text(title)
                    .fontStyle(Fonts.title1)
                    .foregroundColor(Colors.NebulaWhite)
                    .multilineTextAlignment(.leading)
                
                
                Spacer()
                    .frame(height: 8)
                
                // Message
                Text(message)
                    .fontStyle(Fonts.body2)
                    .foregroundColor(.white.opacity(0.8))
                    .foregroundColor(Colors.NebulaWhite)
                    .lineSpacing(2)
                
                Spacer()
                    .frame(height: 30)
                
                // Buttons
                switch style {
                case .twoButtons(let cancelTitle, let confirmTitle, let isDestructive):
                    HStack(spacing: 12) {
                        // Cancel Button
                        Button(action: onCancel) {
                            Text(cancelTitle)
                                .fontStyle(Fonts.callout)
                                .foregroundColor(Colors.NebulaWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Colors.BtnGray)
                                )
                        }
                        
                        // Confirm Button
                        Button(action: onConfirm) {
                            Text(confirmTitle)
                                .fontStyle(Fonts.callout)
                                .foregroundColor(isDestructive ? Colors.NebulaWhite : Colors.BackgroundBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isDestructive ? AnyShapeStyle(Colors.NebulaRed) : AnyShapeStyle(LinearGradient.GradientSub))
                                )
                        }
                    }
                    
                case .singleButton(let buttonTitle):
                    Button(action: onConfirm) {
                        Text(buttonTitle)
                            .fontStyle(Fonts.callout)
                            .foregroundColor(Colors.BackgroundBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(LinearGradient.GradientSub)
                            )
                    }
                }
            }
            .padding(.bottom, 40)
            .padding(.horizontal, 40)
            .frame(minHeight: 256)
            .frame(width: 320)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            Colors.BackgroundBlack.opacity(0.9)
                        )
                    
                    RoundedRectangle(cornerRadius: 40)
                        .fill(
                            LinearGradient.BackgroundPopup
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 40)
                    .stroke(
                        LinearGradient.StrokePopup,
                        lineWidth: 2
                    )
            )
            .modifier(ModalStyleModifier(cornerRadius: 40))
        }
        .transition(.asymmetric(
            insertion: .opacity.animation(.easeInOut(duration: 0.5)),
            removal: .opacity.animation(.easeInOut(duration: 0.5))
        ))
    }
}
