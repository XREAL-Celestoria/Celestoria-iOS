//
//  iOSOnboardingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//


//
//  iOSOnboardingView.swift
//  Celestoria
//
//  Created by Claude on 1/19/25.
//

import SwiftUI

struct iOSOnboardingView: View {
    @State private var currentStep = 1
    @EnvironmentObject var appState: AppState
    
    private let onboardingData: [(title: String, subtitle: String)] = [
        ("Welcome to Celestoria", "Your spatial memories, forever in the stars"),
        ("Capture Your Moments", "Transform your videos into celestial memories"),
        ("Explore the Galaxy", "Discover memories shared by others around the world"),
        ("Ready to Begin", "Let's create your first constellation of memories")
    ]
    
    var body: some View {
        ZStack {
            // Onboarding images not yet added - using placeholder
            Color.NebulaBlack
                .ignoresSafeArea()
                .overlay(
                    Text("onboarding-\(currentStep) image missing")
                        .foregroundColor(.red)
                        .font(.caption)
                )
            
            VStack {
                Spacer()
                
                iOSHeaderView(
                    title: onboardingData[currentStep - 1].title,
                    subtitle: onboardingData[currentStep - 1].subtitle
                )
                .padding(.horizontal, 32)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(1...4, id: \.self) { step in
                        Circle()
                            .fill(currentStep == step ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 32)
                
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
