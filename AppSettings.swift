//
//  AppSettings.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftUI

/// Global app settings manager
@Observable
class AppSettings {
    // MARK: - Singleton
    static let shared = AppSettings()
    
    // MARK: - Audio Settings
    var soundEffectsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled")
            AudioService.shared.soundEffectsEnabled = soundEffectsEnabled
        }
    }

    var backgroundMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundMusicEnabled, forKey: "backgroundMusicEnabled")
            AudioService.shared.backgroundMusicEnabled = backgroundMusicEnabled
        }
    }

    var soundEffectsVolume: Double {
        didSet {
            UserDefaults.standard.set(soundEffectsVolume, forKey: "soundEffectsVolume")
            AudioService.shared.soundEffectsVolume = Float(soundEffectsVolume)
        }
    }

    var backgroundMusicVolume: Double {
        didSet {
            UserDefaults.standard.set(backgroundMusicVolume, forKey: "backgroundMusicVolume")
            AudioService.shared.backgroundMusicVolume = Float(backgroundMusicVolume)
        }
    }
    
    // MARK: - Haptic Settings
    var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }
    
    // MARK: - Accessibility Settings
    var reduceAnimations: Bool {
        didSet {
            UserDefaults.standard.set(reduceAnimations, forKey: "reduceAnimations")
        }
    }
    
    // MARK: - Initialization
    private init() {
        // Load audio settings
        self.soundEffectsEnabled = UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        self.backgroundMusicEnabled = UserDefaults.standard.object(forKey: "backgroundMusicEnabled") as? Bool ?? true
        self.soundEffectsVolume = UserDefaults.standard.object(forKey: "soundEffectsVolume") as? Double ?? 0.7
        self.backgroundMusicVolume = UserDefaults.standard.object(forKey: "backgroundMusicVolume") as? Double ?? 0.3
        
        // Load other settings
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.reduceAnimations = UserDefaults.standard.object(forKey: "reduceAnimations") as? Bool ?? false
    }
    
    // MARK: - Reset
    func resetToDefaults() {
        soundEffectsEnabled = true
        backgroundMusicEnabled = true
        soundEffectsVolume = 0.7
        backgroundMusicVolume = 0.3
        hapticsEnabled = true
        reduceAnimations = false
    }
}

// MARK: - SwiftUI Environment Key

struct AppSettingsKey: EnvironmentKey {
    static let defaultValue = AppSettings.shared
}

extension EnvironmentValues {
    var appSettings: AppSettings {
        get { self[AppSettingsKey.self] }
        set { self[AppSettingsKey.self] = newValue }
    }
}
