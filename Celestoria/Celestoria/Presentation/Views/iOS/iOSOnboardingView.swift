//
//  iOSOnboardingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

struct iOSOnboardingView: View {
    @State private var currentStep = 1
    @EnvironmentObject var appState: AppState
    
    private let onboardingData: [(title: String, subtitle: String)] = [
        ("Turn Moments into Memory Stars", "Create a Memory Star\nby uploading your Spatial Video"),
        ("Design Your Own Galaxy", "Choose a cosmic background\nand build your memory-filled galaxy."),
        ("Take Your Galaxy Everywhere", "View and upload your Memory Stars\ndirectly from your iPhone"),
        ("Explore Other Galaxies", "Explore others’ galaxies and\nconnect through hearts and comments.")
    ]
    
    var body: some View {
        ZStack {
            
            Image("onboardingImage\(currentStep)")
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            
            VStack(alignment: .center) {
                Spacer()
                
                Text(onboardingData[currentStep - 1].title)
                    .font(.system(size: 19, weight: .bold))
                    .padding(.horizontal, 40)
                    .padding(.bottom, 16)
                
                Text(onboardingData[currentStep - 1].subtitle)
                    .font(.system(size: 15, weight: .regular))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 80)
                
                iOSMainButton(
                    title: currentStep < 4 ? "Next" : "Get Started",
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentStep < 4 {
                                currentStep += 1
                            } else {
                                appState.hasCompletedOnboarding = true
                                appState.navigationState = .login
                            }
                        }
                    },
                    isEnabled: true
                )
                .padding(.bottom, 50)
            }
        }
    }
}
