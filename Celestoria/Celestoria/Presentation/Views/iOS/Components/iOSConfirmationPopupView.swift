//
//  iOSPopupView.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/3/25.
//

import SwiftUI

// MARK: - Confirmation Popup View
struct iOSConfirmationPopupView: View {
    let title: String
    let message: String
    let cancelTitle: String
    let confirmTitle: String
    let onCancel: () -> Void
    let onConfirm: () -> Void
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onCancel()
                }
            
            // Popup content
            VStack {
                
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
            .modifier(ModalStyleModifier())
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Delete Memory Confirmation Popup
struct DeleteMemoryConfirmationPopup: View {
    let onCancel: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        iOSConfirmationPopupView(
            title: "Delete Memory Star",
            message: "Are you sure you want to delete this? This action cannot be undone.",
            cancelTitle: "Cancel",
            confirmTitle: "Delete",
            onCancel: onCancel,
            onConfirm: onDelete
        )
    }
}
