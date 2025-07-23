//
//  iOSTermsAndConditionsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSTermsAndConditionsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Full black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Title outside the card
                Text("Terms and Conditions")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.NebulaWhite)
                    .padding(.horizontal, 40)
                
                // Main card container
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Your Agreement inside the card
                        Text("Your Agreement")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.NebulaWhite)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 24)
                        
                        // Terms content
                        Text("""
                        These Terms and Conditions govern the use of this Application. By downloading and using this Application, you agree to these Terms. If you do not agree, please refrain from using the Application.

                        1. Software License Agreement (EULA)
                        This Application is provided to you by Apple Inc. and the developer Celestoria under a license agreement, not a sale. You are granted a limited, non-exclusive, and non-transferable right to use this Application on your Vision Pro device. You may not modify, redistribute, reverse-engineer, or resell this Application without prior written permission from the Provider. The ownership of this Application remains with the Provider.

                        2. Privacy Policy
                        This Application may collect certain user data, including but not limited to:
                        • Location data, voice input, and usage logs
                        • Device information and interaction data for improvement, support, and legal compliance

                        3. User-Generated Content and Community Guidelines
                        Users may create and share content ("User-Generated Content") within the Application. By submitting content, you agree that:
                        • Your content must not contain objectionable, abusive, or inappropriate material
                        • Content may be reviewed by administrators and removed if necessary
                        • Users who violate guidelines may have their access suspended or terminated

                        4. Termination
                        The provider may restrict or terminate access to the Application at any time if these Terms are violated. Users may terminate their use by deleting the Application.

                        5. Governing Law
                        These Terms are governed by the laws applicable to Apple's App Store. Any disputes will be resolved in accordance with Apple's policies.
                        """)
                        .font(.system(size: 14))
                        .foregroundColor(.NebulaWhite.opacity(0.8))
                        .lineSpacing(5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                }
                .frame(maxHeight: 380)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.NebulaWhite.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                
                // Buttons outside the card
                HStack(spacing: 12) {
                    Button(action: {
                        appState.navigationState = .login
                    }) {
                        Text("Cancel")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.NebulaWhite)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(hex: "#2C2C2E"))
                            )
                    }
                    
                    Button(action: {
                        appState.hasAcceptedTerms = true
                        appState.navigationState = .main
                    }) {
                        Text("Agree")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.NebulaBlack)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient.GradientSub)
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
        }
    }
}