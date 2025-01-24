//
//  PopupData.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/24/25.
//

import Foundation

struct PopupData {
    let title: String
    let notes: String
    let leadingButtonText: String
    let trailingButtonText: String
    let buttonImageString: String
    let circularAction: () -> Void
    let leadingButtonAction: () -> Void
    let trailingButtonAction: () -> Void
}
