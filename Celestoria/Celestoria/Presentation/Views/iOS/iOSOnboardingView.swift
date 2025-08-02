//
//  iOSOnboardingView.swift
//  Celestoria
//
//  Created by Minjun Kim on 7/20/25.
//

import SwiftUI

enum VerticalPosition {
    case top
    case bottom
}

struct iOSOnboardingView: View {
    @State private var currentStep = 1
    @EnvironmentObject var appState: AppState
    
    private let onboardingData: [(title: String, subtitle: String, position: VerticalPosition)] = [
        ("Turn Moments into Memory Stars", "Create a Memory Star\nby uploading your Spatial Video", .bottom),
        ("Design Your Own Galaxy", "Choose a cosmic background\nand build your memory-filled galaxy.", .top),
        ("Take Your Galaxy Everywhere", "View and upload your Memory Stars\ndirectly from your iPhone", .bottom),
        ("Explore Other Galaxies", "Explore others' galaxies and\nconnect through hearts and comments.", .top)
    ]
    
    var body: some View {
        ZStack {
            
            Image("Onboarding\(currentStep)")
                .resizable()
                .scaledToFill()
                .clipped()
                .ignoresSafeArea()
            
            VStack(alignment: .center) {
                switch onboardingData[currentStep - 1].position {
                case .top:
                    content
                        .padding(.top, 120)
                    Spacer()
                case .bottom:
                    Spacer()
                    content
                        .padding(.bottom, 50)
                }
                
                iOSMainButton(
                    title: currentStep < 4 ? "Next" : "Get Started",
                    action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if currentStep < 4 {
                                currentStep += 1
                            } else {
                                // 온보딩 완료 시 UserDefaults에 상태 저장
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                appState.hasCompletedOnboarding = true
                                appState.navigationState = .login
                            }
                        }
                    },
                    isEnabled: true
                )
                .padding(.bottom, 60)
            }
        }
    }
    private var content: some View {
           VStack(spacing: 16) {
               Text(onboardingData[currentStep - 1].title)
                   .font(.system(size: 19, weight: .bold))

               Text(onboardingData[currentStep - 1].subtitle)
                   .font(.system(size: 15))
                   .multilineTextAlignment(.center)
           }
       }
}
