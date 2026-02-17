//
//  HapticManager.swift
//  BirdSim
//
//  Created by George Clinkscales on 2/3/26.
//

import UIKit

class HapticManager {
    static let shared = HapticManager()
    
    // Keep generators in memory for instant response
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    private init() {}
    
    enum HapticType {
        case light, medium, heavy, success, error, selection
    }
    
    func trigger(_ type: HapticType) {
        // FIX: Default to TRUE if the key has never been set
        let hapticsEnabled = UserDefaults.standard.object(forKey: "haptics_enabled") as? Bool ?? true
        guard hapticsEnabled else { return }
        
        switch type {
        case .light:
            lightImpact.impactOccurred()
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        case .selection:
            selectionFeedback.selectionChanged()
        }
        
        // Prepare for the next potential tap to reduce latency
        prepare()
    }
    
    /// Call this when a touch starts to "wake up" the haptic engine
    func prepare() {
        selectionFeedback.prepare()
        notificationFeedback.prepare()
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
    }
}
