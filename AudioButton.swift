//
//  AudioButton.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// A button wrapper that adds audio and haptic feedback
struct AudioButton<Label: View>: View {
    @Environment(\.audioService) private var audioService
    @Environment(\.appSettings) private var settings
    
    let action: () -> Void
    let sound: SoundEffect
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    @ViewBuilder let label: Label
    
    init(
        sound: SoundEffect = .buttonTap,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .medium,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.sound = sound
        self.hapticStyle = hapticStyle
        self.action = action
        self.label = label()
    }
    
    var body: some View {
        Button(action: {
            // Audio feedback
            audioService.playSound(sound)
            
            // Haptic feedback
            if settings.hapticsEnabled {
                let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                generator.impactOccurred()
            }
            
            // Execute action
            action()
        }) {
            label
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds audio and haptic feedback to any view tap
    func withAudioFeedback(
        sound: SoundEffect = .buttonTap,
        hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        action: @escaping () -> Void
    ) -> some View {
        modifier(AudioFeedbackModifier(sound: sound, hapticStyle: hapticStyle, action: action))
    }
}

struct AudioFeedbackModifier: ViewModifier {
    @Environment(\.audioService) private var audioService
    @Environment(\.appSettings) private var settings
    
    let sound: SoundEffect
    let hapticStyle: UIImpactFeedbackGenerator.FeedbackStyle
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                audioService.playSound(sound)
                
                if settings.hapticsEnabled {
                    let generator = UIImpactFeedbackGenerator(style: hapticStyle)
                    generator.impactOccurred()
                }
                
                action()
            }
    }
}
