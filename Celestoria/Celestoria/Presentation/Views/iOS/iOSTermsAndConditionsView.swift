//
//  iOSTermsAndConditionsView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSTermsAndConditionsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var settingViewModel: SettingViewModel
    
    var body: some View {
        ZStack {
            Colors.backgroundMain
                .ignoresSafeArea()
            
            VStack {
                .ignoresSafeArea(.container, edges: .bottom)
                // Header
                ZStack {
                    HStack {
                        Button(action: {
                            settingViewModel.resetToLogin()
                        }) {
                            Image("backButton")
                                .resizable()
                                .frame(width: 30, height: 30)
                        }
                        
                        Spacer()
                    }
                    
                    HStack(alignment: .center) {
                        Spacer()
                        
                        Text("Terms and Conditions")
                            .fontStyle(Fonts.headline)
                            .foregroundColor(Colors.NebulaWhite)
                        
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity, minHeight: 48)
                .padding(.horizontal, 14)
                .padding(.bottom, 20)
                
                // ScrollView Content
                ScrollView {
                    VStack(alignment: .center) {
                        Text("Your Agreement")
                            .fontStyle(Fonts.callout)
                            .foregroundColor(Colors.NebulaWhite)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 30)
                        
                        Spacer()
                            .frame(minHeight: 16)
                        
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
                        .fontStyle(Fonts.subheadline)
                        .foregroundColor(Colors.NebulaWhite)
                        .lineSpacing(5)
                        .padding(.horizontal, 30)
                        .padding(.bottom, 30)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 40)
                        .fill(Colors.InputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Colors.GrayStroke)
                        )
                )
                .padding(.horizontal, 24)
                
                // Bottom Buttons
                VStack(spacing: 10) {
                    HStack(spacing: 10) {
                        iOSMainButton(title: "Cancel", action: {settingViewModel.resetToLogin()}, isEnabled: false)
                        
                        iOSMainButton(title: "Agree", action: {
                            UserDefaults.standard.set(true, forKey: "hasAcceptedTerms")
                            appState.hasAcceptedTerms = true
                            appState.navigationState = .main
                        }, isEnabled: true)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 60)
            }
        }
    }
}
