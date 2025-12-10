//
//  MainMenuView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

struct MainMenuView: View {
    @State private var isAnimating = false
    @State private var showPlayers = false
    @State private var showSettings = false
    @State private var showTutorial = false
    @State private var showPlayAlone = false
    @State private var showHotSeat = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Animated gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.3),
                        Color(red: 0.05, green: 0.12, blue: 0.25)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .hueRotation(.degrees(isAnimating ? 10 : 0))
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: isAnimating)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Logo and title
                        VStack(spacing: 12) {
                            Text("🎭")
                                .font(.system(size: 80))
                                .scaleEffect(isAnimating ? 1.1 : 1.0)
                                .animation(
                                    .easeInOut(duration: 2)
                                    .repeatForever(autoreverses: true),
                                    value: isAnimating
                                )
                            
                            Text("Lie Detect")
                                .font(.system(size: 42, weight: .black))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.white, .cyan, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 20)
                        
                        // Menu buttons
                        VStack(spacing: 16) {
                            MenuButton(
                                icon: "person.fill",
                                title: "menu.play_solo".localized,
                                subtitle: "menu.play_solo_subtitle".localized,
                                gradient: [Color.blue, Color.cyan]
                            ) {
                                showPlayAlone = true
                            }

                            MenuButton(
                                icon: "person.3.fill",
                                title: "menu.hot_seat".localized,
                                subtitle: "menu.hot_seat_subtitle".localized,
                                gradient: [Color.orange, Color.red]
                            ) {
                                showHotSeat = true
                            }

                            MenuButton(
                                icon: "wifi",
                                title: "menu.play_online".localized,
                                subtitle: "menu.play_online_subtitle".localized,
                                gradient: [Color.blue, Color.cyan],
                                isDisabled: true
                            ) {
                                // Coming soon
                            }
                        }
                        .padding(.horizontal, 24)

                        // Secondary menu
                        VStack(spacing: 12) {
                            SecondaryMenuButton(
                                icon: "person.2.fill",
                                title: "menu.players".localized
                            ) {
                                showPlayers = true
                            }

                            SecondaryMenuButton(
                                icon: "lightbulb.fill",
                                title: "menu.how_it_works".localized
                            ) {
                                showTutorial = true
                            }

                            SecondaryMenuButton(
                                icon: "gearshape.fill",
                                title: "menu.settings".localized
                            ) {
                                showSettings = true
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $showPlayers) {
                PlayersListView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showTutorial) {
                OnboardingView()
            }
            .fullScreenCover(isPresented: $showPlayAlone) {
                PlayAloneFlowView()
            }
            .fullScreenCover(isPresented: $showHotSeat) {
                HotSeatFlowView()
            }
        }
        .onAppear {
            isAnimating = true
            AudioService.shared.playMenuMusic()
        }
    }
}

struct MenuButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [Color]
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if !isDisabled {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                action()
            }
        }) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: isDisabled ? [Color.gray.opacity(0.3)] : gradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                if !isDisabled {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isDisabled ? 0.05 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: isDisabled ? .clear : (gradient.first ?? .clear).opacity(0.3), radius: 20, y: 10)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .disabled(isDisabled)
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

struct SecondaryMenuButton: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 32)
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.05))
            )
        }
    }
}

// Placeholder views
struct ComingSoonView: View {
    @Environment(\.dismiss) var dismiss
    let title: String
    let message: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 30) {
                Text("🚧")
                    .font(.system(size: 100))

                Text(title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: { dismiss() }) {
                    Text("button.close".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.cyan)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.top, 20)
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var settings = AppSettings.shared
    @State private var localization = LocalizationManager.shared
    @State private var showLanguagePicker = false

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.1, blue: 0.2),
                        Color(red: 0.1, green: 0.15, blue: 0.3)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Audio Section
                        SettingsSection(title: "settings.audio".localized, icon: "speaker.wave.2.fill") {
                            SettingsToggleRow(
                                title: "settings.sound_effects".localized,
                                subtitle: "settings.sound_effects_subtitle".localized,
                                isOn: $settings.soundEffectsEnabled
                            )

                            if settings.soundEffectsEnabled {
                                SettingsSliderRow(
                                    title: "settings.sound_effects_volume".localized,
                                    value: $settings.soundEffectsVolume
                                )
                            }

                            SettingsToggleRow(
                                title: "settings.background_music".localized,
                                subtitle: "settings.background_music_subtitle".localized,
                                isOn: $settings.backgroundMusicEnabled
                            )

                            if settings.backgroundMusicEnabled {
                                SettingsSliderRow(
                                    title: "settings.background_music_volume".localized,
                                    value: $settings.backgroundMusicVolume
                                )
                            }

                            SettingsToggleRow(
                                title: "settings.voice".localized,
                                subtitle: "settings.voice_subtitle".localized,
                                isOn: $settings.voiceEnabled
                            )

                            if settings.voiceEnabled {
                                SettingsSliderRow(
                                    title: "settings.voice_volume".localized,
                                    value: $settings.voiceVolume
                                )
                            }
                        }

                        // Haptics Section
                        SettingsSection(title: "settings.haptics".localized, icon: "waveform") {
                            SettingsToggleRow(
                                title: "settings.haptics_toggle".localized,
                                subtitle: "settings.haptics_subtitle".localized,
                                isOn: $settings.hapticsEnabled
                            )
                        }

                        // Accessibility Section
                        SettingsSection(title: "settings.accessibility".localized, icon: "accessibility") {
                            SettingsToggleRow(
                                title: "settings.reduce_animations".localized,
                                subtitle: "settings.reduce_animations_subtitle".localized,
                                isOn: $settings.reduceAnimations
                            )
                        }

                        // Language Section
                        SettingsSection(title: "settings.language".localized, icon: "globe") {
                            Button(action: { showLanguagePicker = true }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("settings.app_language".localized)
                                            .font(.system(size: 17, weight: .medium))
                                            .foregroundColor(.white)
                                        Text(localization.currentLanguage.nativeName)
                                            .font(.system(size: 14))
                                            .foregroundColor(.cyan)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white.opacity(0.3))
                                }
                                .padding(.vertical, 12)
                            }
                        }

                        // About Section
                        SettingsSection(title: "settings.about".localized, icon: "info.circle.fill") {
                            SettingsInfoRow(title: "settings.version".localized, value: "1.0.0")
                            SettingsInfoRow(title: "settings.platform".localized, value: "iOS")
                        }

                        // Reset Button
                        Button(action: {
                            settings.resetToDefaults()
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }) {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                Text("settings.reset_defaults".localized)
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.red.opacity(0.1))
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
            .sheet(isPresented: $showLanguagePicker) {
                LanguagePickerView(currentLanguage: $localization.currentLanguage)
            }
        }
    }
}

// MARK: - Settings Components

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                Text(title.uppercased())
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 0) {
                content
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 20)
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(.cyan)
        }
        .padding(.vertical, 8)
    }
}

struct SettingsSliderRow: View {
    let title: String
    @Binding var value: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                Spacer()
                Text("\(Int(value * 100))%")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.cyan)
            }
            Slider(value: $value, in: 0...1)
                .tint(.cyan)
        }
        .padding(.vertical, 8)
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 17))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.vertical, 12)
    }
}

struct LanguagePickerView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var currentLanguage: AppLanguage

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.1, blue: 0.2).ignoresSafeArea()

                VStack(spacing: 16) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            currentLanguage = language
                            dismiss()
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.system(size: 32))
                                Text(language.displayName)
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                                if language == currentLanguage {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(language == currentLanguage ? Color.cyan.opacity(0.2) : Color.white.opacity(0.08))
                            )
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle("settings.choose_language".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("button.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

#Preview {
    MainMenuView()
        .modelContainer(for: [Player.self], inMemory: true)
}
