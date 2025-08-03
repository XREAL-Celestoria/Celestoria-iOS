//
//  Text+.swift
//  Celestoria
//
//  Created by Park Seyoung on 7/21/25.
//

import Foundation
import SwiftUI

extension Text {
    func fontStyle(_ fontStyle: FontStyle) -> some View {
        font(fontStyle.toFont())
            .lineSpacing(fontStyle.lineHeight - fontStyle.size) // 줄 높이
            .tracking(fontStyle.letterSpacing) // 자간
    }
}
