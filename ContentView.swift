//
//  ContentView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData
import AVFoundation
import Speech
import ARKit

// MARK: - App Flow State
enum AppFlowState {
    case loading
    case onboarding
    case permissions
    case createFirstPlayer
    case calibration(Player)
    case home
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var flowState: AppFlowState = .loading
    @State private var hasCompletedOnboarding: Bool = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    @State private var hasGrantedPermissions: Bool = false
    @State private var newPlayerToCalibrate: Player?

    var body: some View {
        Group {
            switch flowState {
            case .loading:
                LoadingView()
                    .onAppear {
                        determineInitialState()
                    }

            case .onboarding:
                WelcomeOnboardingView(onComplete: {
                    UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                    hasCompletedOnboarding = true
                    flowState = .permissions
                })

            case .permissions:
                PermissionsView(onComplete: {
                    hasGrantedPermissions = true
                    if players.isEmpty {
                        flowState = .createFirstPlayer
                    } else {
                        flowState = .home
                    }
                })

            case .createFirstPlayer:
                CreatePlayerView(isFirstPlayer: true) { player in
                    newPlayerToCalibrate = player
                    flowState = .calibration(player)
                }

            case .calibration(let player):
                CalibrationFlowView(player: player) {
                    flowState = .home
                }

            case .home:
                MainMenuView()
            }
        }
        .onChange(of: players.count) { oldCount, newCount in
            // If all players are deleted and we're at home, go back to create player
            if newCount == 0 && flowState == .home {
                flowState = .createFirstPlayer
            }
        }
    }

    private func determineInitialState() {
        // Small delay to let SwiftData load
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !hasCompletedOnboarding {
                flowState = .onboarding
            } else if !checkPermissionsGranted() {
                flowState = .permissions
            } else if players.isEmpty {
                flowState = .createFirstPlayer
            } else {
                flowState = .home
            }
        }
    }

    private func checkPermissionsGranted() -> Bool {
        let cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        let microphoneAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let speechAuthorized = SFSpeechRecognizer.authorizationStatus() == .authorized

        return cameraAuthorized && microphoneAuthorized && speechAuthorized
    }
}

// Equatable conformance for AppFlowState
extension AppFlowState: Equatable {
    static func == (lhs: AppFlowState, rhs: AppFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading): return true
        case (.onboarding, .onboarding): return true
        case (.permissions, .permissions): return true
        case (.createFirstPlayer, .createFirstPlayer): return true
        case (.calibration, .calibration): return true
        case (.home, .home): return true
        default: return false
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.2, green: 0.1, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("🎭")
                    .font(.system(size: 80))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Welcome Onboarding View (3-4 pages with image placeholders)

struct WelcomeOnboardingView: View {
    let onComplete: () -> Void

    @State private var currentPage = 0

    let pages: [WelcomeOnboardingPage] = [
        WelcomeOnboardingPage(
            imageName: "waveform.path.ecg.rectangle",
            imageColor: .cyan,
            title: "Witaj w Lie Detect!",
            description: "Gra towarzyska, która analizuje Twoje reakcje i próbuje wykryć, kiedy kłamiesz. Sprawdź, czy potrafisz oszukać wykrywacz!"
        ),
        WelcomeOnboardingPage(
            imageName: "faceid",
            imageColor: .green,
            title: "Analiza twarzy",
            description: "Wykorzystujemy technologię rozpoznawania twarzy, aby analizować Twoje mikro-ekspresje, mruganie i ruchy głowy w czasie rzeczywistym."
        ),
        WelcomeOnboardingPage(
            imageName: "mic.fill",
            imageColor: .orange,
            title: "Rozpoznawanie głosu",
            description: "Odpowiadaj głosowo 'tak' lub 'nie'. Aplikacja automatycznie rozpoznaje Twoją odpowiedź i mierzy czas reakcji."
        ),
        WelcomeOnboardingPage(
            imageName: "person.3.fill",
            imageColor: .purple,
            title: "Graj z przyjaciółmi",
            description: "Tryb Gorącego Krzesła pozwala grać w grupie. Zadawajcie sobie pytania i sprawdźcie, kto jest najlepszym kłamcą!"
        )
    ]

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.12, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: onComplete) {
                        Text("Pomiń")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        WelcomePageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.cyan : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 32)

                // Next/Start button
                Button(action: {
                    if currentPage < pages.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(currentPage < pages.count - 1 ? "Dalej" : "Rozpocznij")
                        Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "arrow.right")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.cyan.opacity(0.4), radius: 15, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
    }
}

struct WelcomeOnboardingPage {
    let imageName: String
    let imageColor: Color
    let title: String
    let description: String
}

struct WelcomePageView: View {
    let page: WelcomeOnboardingPage
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Image placeholder with SF Symbol
            ZStack {
                // Glow effect
                Circle()
                    .fill(page.imageColor.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .scaleEffect(isAnimating ? 1.2 : 0.9)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Placeholder frame (replace with actual image later)
                RoundedRectangle(cornerRadius: 32)
                    .fill(
                        LinearGradient(
                            colors: [page.imageColor.opacity(0.3), page.imageColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .overlay(
                        RoundedRectangle(cornerRadius: 32)
                            .stroke(page.imageColor.opacity(0.5), lineWidth: 2)
                    )

                // Icon (temporary - can be replaced with Image)
                Image(systemName: page.imageName)
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.imageColor, page.imageColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.description)
                    .font(.system(size: 17))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Permissions View

struct PermissionsView: View {
    let onComplete: () -> Void

    @State private var cameraStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    @State private var microphoneStatus: AVAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
    @State private var speechStatus: SFSpeechRecognizerAuthorizationStatus = SFSpeechRecognizer.authorizationStatus()
    @State private var isAnimating = false

    var allPermissionsGranted: Bool {
        cameraStatus == .authorized &&
        microphoneStatus == .authorized &&
        speechStatus == .authorized
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.12, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 140, height: 140)
                        .blur(radius: 30)
                        .scaleEffect(isAnimating ? 1.2 : 0.9)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }

                // Title
                VStack(spacing: 12) {
                    Text("Potrzebujemy uprawnień")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Aby aplikacja działała poprawnie, potrzebujemy dostępu do kamery, mikrofonu i rozpoznawania mowy.")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Permission items
                VStack(spacing: 16) {
                    PermissionRow(
                        icon: "camera.fill",
                        title: "Kamera",
                        description: "Do analizy mimiki twarzy",
                        status: cameraStatus == .authorized ? .granted : (cameraStatus == .denied ? .denied : .notDetermined),
                        action: requestCameraPermission
                    )

                    PermissionRow(
                        icon: "mic.fill",
                        title: "Mikrofon",
                        description: "Do nagrywania odpowiedzi głosowych",
                        status: microphoneStatus == .authorized ? .granted : (microphoneStatus == .denied ? .denied : .notDetermined),
                        action: requestMicrophonePermission
                    )

                    PermissionRow(
                        icon: "waveform",
                        title: "Rozpoznawanie mowy",
                        description: "Do rozpoznawania 'tak' lub 'nie'",
                        status: speechStatus == .authorized ? .granted : (speechStatus == .denied ? .denied : .notDetermined),
                        action: requestSpeechPermission
                    )
                }
                .padding(.horizontal, 24)

                Spacer()

                // Continue button
                Button(action: {
                    if allPermissionsGranted {
                        onComplete()
                    } else {
                        // Request all permissions in sequence
                        requestAllPermissions()
                    }
                }) {
                    HStack(spacing: 8) {
                        Text(allPermissionsGranted ? "Kontynuuj" : "Nadaj uprawnienia")
                        Image(systemName: allPermissionsGranted ? "arrow.right" : "hand.tap.fill")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                allPermissionsGranted ?
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: (allPermissionsGranted ? Color.green : Color.cyan).opacity(0.4), radius: 15, y: 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            isAnimating = true
            refreshPermissionStatuses()
        }
    }

    private func refreshPermissionStatuses() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        speechStatus = SFSpeechRecognizer.authorizationStatus()
    }

    private func requestAllPermissions() {
        requestCameraPermission()
    }

    private func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
                if cameraStatus == .authorized {
                    requestMicrophonePermission()
                }
            }
        }
    }

    private func requestMicrophonePermission() {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            DispatchQueue.main.async {
                microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
                if microphoneStatus == .authorized {
                    requestSpeechPermission()
                }
            }
        }
    }

    private func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                speechStatus = status
            }
        }
    }
}

enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus
    let action: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(statusColor.opacity(0.15))
                )

            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Status indicator
            statusIcon
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(statusColor.opacity(0.3), lineWidth: 1)
        )
        .onTapGesture {
            if status == .notDetermined {
                action()
            } else if status == .denied {
                // Open settings
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
        }
    }

    private var statusColor: Color {
        switch status {
        case .notDetermined: return .orange
        case .granted: return .green
        case .denied: return .red
        }
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .notDetermined:
            Image(systemName: "circle")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.orange)
        case .granted:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.green)
        case .denied:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.red)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Player.self], inMemory: true)
}
