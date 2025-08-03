//
//  iOSUploadButton.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/4/25.
//

import Foundation
import AudioToolbox
import SwiftUI

struct iOSUploadButton: View {
    let title: String
    let action: () -> Void
    let isEnabled: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .fontStyle(Fonts.title3)
                .foregroundColor(isEnabled ? Colors.NebulaBlack : Colors.BtnBeforeSelectText)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isEnabled ?
                            AnyShapeStyle(LinearGradient.GradientSub) :
                                AnyShapeStyle(LinearGradient.BtnBeforeSelect))
                .cornerRadius(16)
        }
        .buttonStyle(iOSMainButtonStyle())
    }
}


