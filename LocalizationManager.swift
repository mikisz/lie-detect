//
//  LocalizationManager.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftUI

/// Manages app localization and language switching
@Observable
class LocalizationManager {
    // MARK: - Singleton
    static let shared = LocalizationManager()
    
    // MARK: - Current Language
    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: "appLanguage")
            updateLocale()
        }
    }
    
    private var bundle: Bundle = Bundle.main
    
    // MARK: - Initialization
    private init() {
        // Load saved language or use system default
        if let savedLang = UserDefaults.standard.string(forKey: "appLanguage"),
           let language = AppLanguage(rawValue: savedLang) {
            self.currentLanguage = language
        } else {
            // Detect system language
            self.currentLanguage = Self.detectSystemLanguage()
        }
        
        updateLocale()
    }
    
    // MARK: - Language Detection
    private static func detectSystemLanguage() -> AppLanguage {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en"
        
        if preferredLanguage.starts(with: "pl") {
            return .polish
        } else {
            return .english
        }
    }
    
    // MARK: - Bundle Management
    private func updateLocale() {
        if let path = Bundle.main.path(forResource: currentLanguage.code, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    // MARK: - Localization
    func localized(_ key: String, comment: String = "") -> String {
        return NSLocalizedString(key, bundle: bundle, comment: comment)
    }
    
    // Convenience method for formatted strings
    func localized(_ key: String, _ args: CVarArg...) -> String {
        let format = localized(key)
        return String(format: format, arguments: args)
    }
}

// MARK: - App Language Enum

enum AppLanguage: String, CaseIterable {
    case polish = "pl"
    case english = "en"
    
    var code: String {
        return rawValue
    }
    
    var displayName: String {
        switch self {
        case .polish: return "Polski"
        case .english: return "English"
        }
    }
    
    var nativeName: String {
        switch self {
        case .polish: return "Polski 🇵🇱"
        case .english: return "English 🇬🇧"
        }
    }
    
    var flag: String {
        switch self {
        case .polish: return "🇵🇱"
        case .english: return "🇬🇧"
        }
    }
}

// MARK: - SwiftUI Environment Key

struct LocalizationManagerKey: EnvironmentKey {
    static let defaultValue = LocalizationManager.shared
}

extension EnvironmentValues {
    var localization: LocalizationManager {
        get { self[LocalizationManagerKey.self] }
        set { self[LocalizationManagerKey.self] = newValue }
    }
}

// MARK: - String Extension

extension String {
    /// Convenience property for localization
    var localized: String {
        return LocalizationManager.shared.localized(self)
    }
    
    /// Localized with arguments
    func localized(_ args: CVarArg...) -> String {
        let format = LocalizationManager.shared.localized(self)
        return String(format: format, arguments: args)
    }
}

// MARK: - View Extension

extension View {
    /// Apply localization to the view
    func withLocalization() -> some View {
        self.environment(\.localization, LocalizationManager.shared)
    }
}

// MARK: - Localization Keys

/// Centralized localization keys for type safety
enum LocalizedKey {
    // MARK: - General
    static let appName = "app.name"
    static let ok = "general.ok"
    static let cancel = "general.cancel"
    static let done = "general.done"
    static let yes = "general.yes"
    static let no = "general.no"
    static let close = "general.close"
    static let save = "general.save"
    static let delete = "general.delete"
    static let edit = "general.edit"
    static let back = "general.back"
    static let next = "general.next"
    static let start = "general.start"
    static let continue_ = "general.continue"
    
    // MARK: - Main Menu
    static let mainMenuTitle = "menu.title"
    static let playSolo = "menu.play_solo"
    static let playSoloSubtitle = "menu.play_solo_subtitle"
    static let hotSeat = "menu.hot_seat"
    static let hotSeatSubtitle = "menu.hot_seat_subtitle"
    static let playOnline = "menu.play_online"
    static let playOnlineSubtitle = "menu.play_online_subtitle"
    static let players = "menu.players"
    static let howItWorks = "menu.how_it_works"
    static let settings = "menu.settings"
    
    // MARK: - Settings
    static let settingsTitle = "settings.title"
    static let audioSection = "settings.audio"
    static let soundEffects = "settings.sound_effects"
    static let soundEffectsSubtitle = "settings.sound_effects_subtitle"
    static let soundEffectsVolume = "settings.sound_effects_volume"
    static let backgroundMusic = "settings.background_music"
    static let backgroundMusicSubtitle = "settings.background_music_subtitle"
    static let backgroundMusicVolume = "settings.background_music_volume"
    static let hapticsSection = "settings.haptics"
    static let hapticsToggle = "settings.haptics_toggle"
    static let hapticsSubtitle = "settings.haptics_subtitle"
    static let accessibilitySection = "settings.accessibility"
    static let reduceAnimations = "settings.reduce_animations"
    static let reduceAnimationsSubtitle = "settings.reduce_animations_subtitle"
    static let languageSection = "settings.language"
    static let languageTitle = "settings.language_title"
    static let languageSubtitle = "settings.language_subtitle"
    static let aboutSection = "settings.about"
    static let version = "settings.version"
    static let platform = "settings.platform"
    static let language = "settings.language"
    static let resetDefaults = "settings.reset_defaults"
    static let testSounds = "settings.test_sounds"
    
    // MARK: - Player
    static let createPlayer = "player.create"
    static let editPlayer = "player.edit"
    static let playerName = "player.name"
    static let playerAge = "player.age"
    static let playerGender = "player.gender"
    static let genderMale = "player.gender.male"
    static let genderFemale = "player.gender.female"
    static let genderOther = "player.gender.other"
    static let calibrated = "player.calibrated"
    static let notCalibrated = "player.not_calibrated"
    static let calibrate = "player.calibrate"
    static let recalibrate = "player.recalibrate"
    
    // MARK: - Calibration
    static let calibrationTitle = "calibration.title"
    static let calibrationSubtitle = "calibration.subtitle"
    static let calibrationInstructions = "calibration.instructions"
    static let calibrationStart = "calibration.start"
    static let calibrationReady = "calibration.ready"
    static let calibrationComplete = "calibration.complete"
    static let calibrationQuestion = "calibration.question"
    
    // MARK: - Game
    static let gameSelectPlayer = "game.select_player"
    static let gameSelectPack = "game.select_pack"
    static let gameStarting = "game.starting"
    static let gameQuestionOf = "game.question_of"
    static let gameRecording = "game.recording"
    static let gameAnalyzing = "game.analyzing"
    static let gameVerdict = "game.verdict"
    static let gameComplete = "game.complete"
    
    // MARK: - Verdict
    static let verdictTruthful = "verdict.truthful"
    static let verdictSuspicious = "verdict.suspicious"
    static let verdictConfidence = "verdict.confidence"
    static let verdictFactors = "verdict.factors"
    
    // MARK: - Face Quality
    static let faceQualityUnknown = "face.quality.unknown"
    static let faceQualityPoor = "face.quality.poor"
    static let faceQualityFair = "face.quality.fair"
    static let faceQualityGood = "face.quality.good"
    
    // MARK: - Question Packs
    static let packQuick = "pack.quick"
    static let packStandard = "pack.standard"
    static let packExtended = "pack.extended"
    static let packSpicy = "pack.spicy"
}
