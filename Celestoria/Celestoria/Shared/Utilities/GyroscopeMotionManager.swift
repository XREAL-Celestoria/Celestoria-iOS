//
//  GyroscopeMotionManager.swift
//  Celestoria-iOS
//
//  Created by Seyoung Park on 8/5/25.
//

import SwiftUI
import CoreMotion

// MARK: - Motion Manager
class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var pitch: Double = 0
    @Published var roll: Double = 0
    
    // Baseline values for calibration
    private var baselinePitch: Double = 0
    private var baselineRoll: Double = 0
    private var calibrationTimer: Timer?
    private let calibrationSpeed: Double = 0.1 // Higher = faster calibration
    private var isInitialized = false
    
    init() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion else { return }
                
                // Initialize baseline on first update
                if !(self?.isInitialized ?? false) {
                    self?.baselinePitch = motion.attitude.pitch
                    self?.baselineRoll = motion.attitude.roll
                    self?.isInitialized = true
                }
                
                self?.updateRotation(motion: motion)
            }
            
            // Start calibration timer
            calibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.calibrateBaseline()
            }
        }
    }
    
    private func updateRotation(motion: CMDeviceMotion) {
        let rawPitch = motion.attitude.pitch
        let rawRoll = motion.attitude.roll
        
        // Apply differential rotation (current - baseline)
        pitch = rawPitch - baselinePitch
        roll = rawRoll - baselineRoll
    }
    
    private func calibrateBaseline() {
        guard let motion = motionManager.deviceMotion else { return }
        
        let targetPitch = motion.attitude.pitch
        let targetRoll = motion.attitude.roll
        
        // Slowly lerp baseline towards current orientation
        baselinePitch += (targetPitch - baselinePitch) * calibrationSpeed
        baselineRoll += (targetRoll - baselineRoll) * calibrationSpeed
    }
    
    deinit {
        calibrationTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }
}
