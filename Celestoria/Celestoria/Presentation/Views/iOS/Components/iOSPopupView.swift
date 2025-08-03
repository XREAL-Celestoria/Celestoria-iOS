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
            VStack(spacing: 20) {
                // Title
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                
                // Message
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                
                // Buttons
                HStack(spacing: 12) {
                    // Cancel Button
                    Button(action: onCancel) {
                        Text(cancelTitle)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.3))
                            )
                    }
                    
                    // Confirm Button
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(red: 0.8, green: 0.9, blue: 1.0))
                            )
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.1, green: 0.1, blue: 0.15),
                                Color(red: 0.05, green: 0.05, blue: 0.1)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(stops: [
                                Gradient.Stop(color: Color(hex: "CFF4FF").opacity(0.4), location: 0.0),
                                Gradient.Stop(color: Color.white.opacity(0.0), location: 0.41),
                                Gradient.Stop(color: Color.white.opacity(0.0), location: 0.62),
                                Gradient.Stop(color: Color(hex: "CFF4FF").opacity(0.2), location: 1.0)
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            .shadow(color: Color(hex: "CFF4FF").opacity(0.3), radius: 20, x: 0, y: 10)
            .shadow(color: Color(hex: "CFF4FF").opacity(0.2), radius: 30, x: 0, y: 20)
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

// MARK: - Usage Example
struct PopupExampleView: View {
    @State private var showDeletePopup = false
    
    var body: some View {
        ZStack {
            // Your main content here
            VStack {
                Text("Main Content")
                    .font(.title)
                    .foregroundColor(.white)
                
                Button("Show Delete Popup") {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        showDeletePopup = true
                    }
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            
            // Popup overlay
            if showDeletePopup {
                DeleteMemoryConfirmationPopup(
                    onCancel: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showDeletePopup = false
                        }
                    },
                    onDelete: {
                        // Handle delete action
                        print("Delete confirmed")
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showDeletePopup = false
                        }
                    }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
            }
        }
        .background(Color.black)
    }
} 