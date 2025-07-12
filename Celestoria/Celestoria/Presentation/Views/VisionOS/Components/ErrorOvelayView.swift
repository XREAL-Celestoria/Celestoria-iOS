//
//  ErrorOvelayView.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import SwiftUI

struct ErrorOverlayView: View {
    var message: String
    var dismissAction: () -> Void

    var body: some View {
        VStack {
            ErrorBannerView(message: message, dismissAction: dismissAction)
                .padding(.top, 10)
        }
    }
}
