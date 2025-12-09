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

    var voiceEnabled: Bool {
        didSet {
            UserDefaults.standard.set(voiceEnabled, forKey: "voiceEnabled")
            AudioService.shared.voiceEnabled = voiceEnabled
        }
    }

    var voiceVolume: Double {
        didSet {
            UserDefaults.standard.set(voiceVolume, forKey: "voiceVolume")
            AudioService.shared.voiceVolume = Float(voiceVolume)
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
        self.voiceEnabled = UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
        self.voiceVolume = UserDefaults.standard.object(forKey: "voiceVolume") as? Double ?? 0.8

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
        voiceEnabled = true
        voiceVolume = 0.8
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
