//
//  iOSTermsAndConditionsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


//
//  iOSTermsAndConditionsView.swift
//  Celestoria
//
//  Created by Assistant on 2025/07/19.
//

import SwiftUI

struct iOSTermsAndConditionsView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ZStack {
            // Full black background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // White card container
                VStack(spacing: 20) {
                    // Header
                    Text("Terms and Conditions")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.top, 30)
                    
                    Text("Your Agreement")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    // Terms content in dark container
                    ScrollView {
                        Text("""
                        These Terms and Conditions govern the use of the Celestoria application ("Application") for Apple Vision Pro. By downloading and using this Application, you agree to be bound by these Terms. If you do not agree, please do not use the Application.

                        1. Software License
                        This Application is provided to you under a limited, non-exclusive, and non-transferable license. You are granted the right to use the Application on your Vision Pro device. Modification, redistribution, reverse-engineering, or resale of this Application is prohibited without prior written consent from the provider.

                        2. Privacy Policy
                        The Application may collect user data (e.g., location data, voice input, usage logs, device information, and interaction data) to improve performance, provide support, and comply with legal requirements. Please review our complete Privacy Policy for further details.

                        3. User-Generated Content and Community Guidelines
                            a. Content Submission and Responsibility:
                        """)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 20)
                    }
                    .frame(height: 400)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(white: 0.15))
                    )
                    .padding(.horizontal, 20)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            appState.navigationState = .login
                        }) {
                            Text("Cancel")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color(white: 0.2))
                                )
                        }
                        
                        Button(action: {
                            appState.hasAcceptedTerms = true
                            appState.navigationState = .main
                        }) {
                            Text("Agree")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white)
                                )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
                .background(
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color(white: 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 30)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
            }
        }
    }
}