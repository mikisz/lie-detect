//
//  AudioService.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import AVFoundation
import SwiftUI

/// Service responsible for playing sound effects and background music
@Observable
class AudioService {
    // MARK: - Singleton
    static let shared = AudioService()

    // MARK: - Error State
    var lastError: String? = nil
    var hasError: Bool { lastError != nil }

    /// Clear any error state
    func clearError() {
        lastError = nil
    }

    // MARK: - Settings (synced with AppSettings)
    var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: "soundEffectsEnabled") }
    }

    var backgroundMusicEnabled: Bool {
        didSet {
            UserDefaults.standard.set(backgroundMusicEnabled, forKey: "backgroundMusicEnabled")
            updateBackgroundMusic()
        }
    }

    var soundEffectsVolume: Float {
        didSet {
            UserDefaults.standard.set(soundEffectsVolume, forKey: "soundEffectsVolume")
            updateEffectsVolume()
        }
    }

    var backgroundMusicVolume: Float {
        didSet {
            UserDefaults.standard.set(backgroundMusicVolume, forKey: "backgroundMusicVolume")
            updateMusicVolume()
        }
    }

    var voiceEnabled: Bool {
        didSet { UserDefaults.standard.set(voiceEnabled, forKey: "voiceEnabled") }
    }

    var voiceVolume: Float {
        didSet { UserDefaults.standard.set(voiceVolume, forKey: "voiceVolume") }
    }

    // MARK: - Audio Players
    private var musicPlayer: AVAudioPlayer?
    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private var voicePlayer: AVAudioPlayer?

    // MARK: - Initialization
    private init() {
        // Load settings
        self.soundEffectsEnabled = UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        self.backgroundMusicEnabled = UserDefaults.standard.object(forKey: "backgroundMusicEnabled") as? Bool ?? true
        self.soundEffectsVolume = UserDefaults.standard.object(forKey: "soundEffectsVolume") as? Float ?? 0.7
        self.backgroundMusicVolume = UserDefaults.standard.object(forKey: "backgroundMusicVolume") as? Float ?? 0.3
        self.voiceEnabled = UserDefaults.standard.object(forKey: "voiceEnabled") as? Bool ?? true
        self.voiceVolume = UserDefaults.standard.object(forKey: "voiceVolume") as? Float ?? 0.8

        setupAudioSession()
        preloadSoundEffects()
    }

    // MARK: - Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true)
        } catch {
            let errorMessage = "audio.setup_failed".localized
            print("❌ Failed to setup audio session: \(error)")
            lastError = errorMessage
        }
    }

    private func preloadSoundEffects() {
        // Preload common sound effects for instant playback
        let commonSounds: [SoundEffect] = [
            .buttonTap,
            .success,
            .warning,
            .countdown,
            .reveal,
            .suspicious,
            .truthful
        ]

        for sound in commonSounds {
            _ = getEffectPlayer(for: sound)
        }
    }

    // MARK: - Sound Effects

    func playSound(_ effect: SoundEffect) {
        guard soundEffectsEnabled else { return }

        if let player = getEffectPlayer(for: effect) {
            player.currentTime = 0
            player.volume = soundEffectsVolume
            player.play()
        }
    }

    private func getEffectPlayer(for effect: SoundEffect) -> AVAudioPlayer? {
        // Check if already loaded
        if let player = effectPlayers[effect.fileName] {
            return player
        }

        // Load from bundle
        guard let url = effect.fileURL else {
            print("⚠️ Sound effect not found: \(effect.fileName)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            effectPlayers[effect.fileName] = player
            return player
        } catch {
            print("❌ Failed to load sound effect \(effect.fileName): \(error)")
            return nil
        }
    }

    private func updateEffectsVolume() {
        for player in effectPlayers.values {
            player.volume = soundEffectsVolume
        }
    }

    // MARK: - Background Music

    func startBackgroundMusic(_ track: MusicTrack = .ambient) {
        guard backgroundMusicEnabled else { return }

        // Stop current music if playing
        stopBackgroundMusic()

        guard let url = track.fileURL else {
            print("⚠️ Music track not found: \(track.fileName)")
            return
        }

        do {
            musicPlayer = try AVAudioPlayer(contentsOf: url)
            musicPlayer?.numberOfLoops = -1 // Loop indefinitely
            musicPlayer?.volume = backgroundMusicVolume
            musicPlayer?.prepareToPlay()
            musicPlayer?.play()

            print("🎵 Started background music: \(track.fileName)")
        } catch {
            print("❌ Failed to start background music: \(error)")
        }
    }

    func stopBackgroundMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func pauseBackgroundMusic() {
        musicPlayer?.pause()
    }

    func resumeBackgroundMusic() {
        guard backgroundMusicEnabled else { return }
        musicPlayer?.play()
    }

    private func updateBackgroundMusic() {
        if backgroundMusicEnabled {
            if musicPlayer == nil {
                startBackgroundMusic()
            } else {
                resumeBackgroundMusic()
            }
        } else {
            pauseBackgroundMusic()
        }
    }

    private func updateMusicVolume() {
        musicPlayer?.volume = backgroundMusicVolume
    }

    // MARK: - Context-Aware Music

    func playMenuMusic() {
        startBackgroundMusic(.ambient)
    }

    func playGameMusic() {
        startBackgroundMusic(.suspense)
    }

    func playCalibrationMusic() {
        startBackgroundMusic(.calm)
    }

    // MARK: - Voice Announcements

    func playVoice(_ announcement: VoiceAnnouncement) {
        guard voiceEnabled else { return }

        let language = LocalizationManager.shared.currentLanguage.rawValue
        let filename = announcement.filename(for: language)

        guard let url = Bundle.main.url(forResource: filename, withExtension: "mp3") else {
            print("⚠️ Voice file not found: \(filename).mp3")
            return
        }

        do {
            voicePlayer = try AVAudioPlayer(contentsOf: url)
            voicePlayer?.volume = voiceVolume
            voicePlayer?.play()
            print("🎙️ Playing voice: \(filename)")
        } catch {
            print("❌ Voice playback error: \(error)")
        }
    }
}

// MARK: - Sound Effect Enum

enum SoundEffect {
    case buttonTap
    case success
    case error
    case warning
    case countdown
    case tick
    case reveal
    case suspense
    case suspicious
    case truthful
    case whoosh
    case pop
    case ding

    var fileName: String {
        switch self {
        case .buttonTap: return "button_tap.mp3"
        case .success: return "success.mp3"
        case .error: return "error.mp3"
        case .warning: return "warning.mp3"
        case .countdown: return "countdown.mp3"
        case .tick: return "tick.mp3"
        case .reveal: return "reveal.mp3"
        case .suspense: return "suspense.mp3"
        case .suspicious: return "suspicious.mp3"
        case .truthful: return "truthful.mp3"
        case .whoosh: return "whoosh.mp3"
        case .pop: return "pop.mp3"
        case .ding: return "ding.mp3"
        }
    }

    var fileURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}

// MARK: - Music Track Enum

enum MusicTrack {
    case ambient    // Main menu
    case suspense   // Game sessions
    case calm       // Calibration
    case victory    // Success screens

    var fileName: String {
        switch self {
        case .ambient: return "ambient_menu.mp3"
        case .suspense: return "suspense_game.mp3"
        case .calm: return "calm_calibration.mp3"
        case .victory: return "victory.mp3"
        }
    }

    var fileURL: URL? {
        Bundle.main.url(forResource: fileName, withExtension: nil)
    }
}

// MARK: - Voice Announcement Enum

enum VoiceAnnouncement: String {
    case verdictIntro = "voice_verdict_intro"
    case verdictTruth = "voice_verdict_truth"
    case verdictSuspicious = "voice_verdict_suspicious"
    case countdown3 = "voice_countdown_3"
    case countdown2 = "voice_countdown_2"
    case countdown1 = "voice_countdown_1"
    case countdownGo = "voice_countdown_go"

    func filename(for language: String) -> String {
        "\(rawValue)_\(language)"
    }
}

// MARK: - SwiftUI Environment Key

struct AudioServiceKey: EnvironmentKey {
    static let defaultValue = AudioService.shared
}

extension EnvironmentValues {
    var audioService: AudioService {
        get { self[AudioServiceKey.self] }
        set { self[AudioServiceKey.self] = newValue }
    }
}
