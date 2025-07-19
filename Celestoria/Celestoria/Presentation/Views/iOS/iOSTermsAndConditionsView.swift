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
            // Background
            Color.NebulaBlack
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Bar
                iOSNavigationBar(
                    title: "Terms and Conditions",
                    action: {
                        appState.activeScreen = .login
                    },
                    buttonImageString: "chevron.left"
                )
                
                // Content
                VStack(spacing: 20) {
                    HStack {
                        Text("Your Agreement")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.NebulaWhite)
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    
                    // Terms content
                    ScrollView {
                        Text("""
                        These Terms and Conditions govern the use of the Celestoria application ("Application") for Apple Vision Pro. By downloading and using this Application, you agree to be bound by these Terms. If you do not agree, please do not use the Application.

                        1. Software License  
                        This Application is provided to you under a limited, non-exclusive, and non-transferable license. You are granted the right to use the Application on your Vision Pro device. Modification, redistribution, reverse-engineering, or resale of this Application is prohibited without prior written consent from the provider.

                        2. Privacy Policy  
                        The Application may collect user data (e.g., location data, voice input, usage logs, device information, and interaction data) to improve performance, provide support, and comply with legal requirements. Please review our complete Privacy Policy for further details.

                        3. User-Generated Content and Community Guidelines  
                            a. Content Submission and Responsibility:  
                                Users are permitted to create and share content ("User-Generated Content"). By submitting content, you agree that it must not contain objectionable, abusive, or otherwise inappropriate material.
                            
                            b. Content Moderation:  
                                - Administrator Review: Administrators review newly submitted content twice daily.  
                                - User Reporting: If a post is reported by one or more users, it is reviewed within one hour. Posts receiving three or more reports are automatically blocked pending further review.
                                
                            c. User Conduct and Blocking:  
                                Users are required to conduct themselves respectfully. The Application provides an option to block abusive users. The provider reserves the right to remove content and suspend or terminate access for any user who violates these guidelines.
                                
                            d. Prompt Action:  
                                All reports of objectionable content are addressed within 24 hours. Appropriate actions include removal of content and ejection of the offending user from the Application.

                        4. Terms of Service  
                        The Application must not be used for illegal activities or to infringe on the rights of others. The provider reserves the right to update or discontinue any part of the Application at any time.

                        5. Limitation of Liability  
                        The Application is provided "as-is" without warranties of any kind. The provider is not liable for any damages resulting from the use of this Application.

                        6. Termination  
                        The provider may restrict or terminate access to the Application at any time if these Terms are violated. Users may terminate their use by deleting the Application.

                        7. Governing Law  
                        These Terms are governed by the laws applicable to Apple's App Store. Any disputes will be resolved in accordance with Apple's policies.

                        8. Amendments  
                        The provider may modify these Terms as necessary. Users will be notified of changes via in-app notifications or on our official website. Continued use of the Application signifies acceptance of the updated Terms.
                        """)
                            .font(.system(size: 14))
                            .foregroundColor(.NebulaWhite)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                    }
                    .background(Color.Profile.opacity(0.2))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.NebulaWhite.opacity(0.2), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    // Buttons
                    HStack(spacing: 16) {
                        Button(action: {
                            appState.activeScreen = .login
                        }) {
                            Text("Cancel")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.NebulaWhite)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "#1B212A"))
                                .cornerRadius(12)
                        }
                        
                        Button(action: {
                            appState.hasAcceptedTerms = true
                            appState.activeScreen = .main
                        }) {
                            Text("Agree")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.NebulaBlack)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(LinearGradient.GradientSub)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
}