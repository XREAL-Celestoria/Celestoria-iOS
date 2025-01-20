//
//  Logger.swift
//  Celestoria
//
//  Created by Park Seyoung on 1/20/25.
//

import os

extension Logger {
    static let space = Logger(subsystem: "com.Celestoria.Celestoria", category: "Space")
    
    static func info(_ message: String) {
        space.log(level: .info, "ℹ️ INFO: \(message)")
    }

    // Debug log with emoji
    static func debug(_ message: String) {
        space.log(level: .debug, "✅ DEBUG: \(message)")
    }

    // Error log with emoji
    static func error(_ message: String) {
        space.log(level: .error, "❌ ERROR: \(message)")
    }

    // Warning log with emoji
    static func warning(_ message: String) {
        space.log(level: .default, "⚠️ WARNING: \(message)")
    }
}
