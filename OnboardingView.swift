//
//  OnboardingView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// Comprehensive onboarding flow for new users
struct OnboardingView: View {
    @Environment(\.dismiss) var dismiss

    @State private var currentPage = 0
    @State private var isAnimating = false

    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "waveform.path.ecg",
            iconColor: .cyan,
            title: "Witaj w Lie Detect",
            subtitle: "Gra towarzyska wykrywająca kłamstwa",
            description: "Czy potrafisz oszukać wykrywacz? Sprawdź się sam lub zagraj z przyjaciółmi!",
            features: []
        ),
        OnboardingPage(
            icon: "faceid",
            iconColor: .green,
            title: "Śledzenie twarzy",
            subtitle: "Zaawansowana analiza mimiki",
            description: "Kamera przedniego telefonu analizuje Twoje mikro-ekspresje, mruganie i ruchy głowy w czasie rzeczywistym.",
            features: [
                OnboardingFeature(icon: "eye", text: "Częstotliwość mrugania"),
                OnboardingFeature(icon: "arrow.up.and.down.and.arrow.left.and.right", text: "Ruchy głowy"),
                OnboardingFeature(icon: "face.smiling", text: "Napięcie mięśni twarzy")
            ]
        ),
        OnboardingPage(
            icon: "mic.fill",
            iconColor: .orange,
            title: "Rozpoznawanie mowy",
            subtitle: "Odpowiadaj głosowo",
            description: "Powiedz 'tak' lub 'nie' - aplikacja automatycznie rozpoznaje Twoją odpowiedź i analizuje czas reakcji.",
            features: [
                OnboardingFeature(icon: "clock", text: "Czas odpowiedzi"),
                OnboardingFeature(icon: "waveform", text: "Rozpoznawanie głosu"),
                OnboardingFeature(icon: "checkmark.circle", text: "Automatyczna detekcja")
            ]
        ),
        OnboardingPage(
            icon: "person.crop.circle.badge.checkmark",
            iconColor: .blue,
            title: "Kalibracja",
            subtitle: "Poznajemy Twoje naturalne reakcje",
            description: "Przed grą odpowiesz na kilka prostych pytań PRAWDZIWIE. To pozwoli nam ustalić Twoją bazę reakcji.",
            features: [
                OnboardingFeature(icon: "1.circle.fill", text: "Stwórz profil gracza"),
                OnboardingFeature(icon: "2.circle.fill", text: "Odpowiedz na 8 pytań prawdą"),
                OnboardingFeature(icon: "3.circle.fill", text: "Gotowe! Możesz grać")
            ]
        ),
        OnboardingPage(
            icon: "lightbulb.fill",
            iconColor: .yellow,
            title: "Wskazówki",
            subtitle: "Dla najlepszych wyników",
            description: "Postępuj zgodnie z tymi wskazówkami, aby uzyskać najdokładniejsze wyniki.",
            features: [
                OnboardingFeature(icon: "sun.max.fill", text: "Graj w dobrze oświetlonym miejscu"),
                OnboardingFeature(icon: "eye.fill", text: "Patrz prosto w kamerę"),
                OnboardingFeature(icon: "person.fill", text: "Bądź naturalny i zrelaksowany"),
                OnboardingFeature(icon: "speaker.wave.2.fill", text: "Mów wyraźnie")
            ]
        ),
        OnboardingPage(
            icon: "exclamationmark.triangle.fill",
            iconColor: .red,
            title: "Ważne!",
            subtitle: "To jest gra rozrywkowa",
            description: "Lie Detect to aplikacja stworzona dla zabawy. NIE jest prawdziwym wykrywaczem kłamstw i nie powinna być używana do poważnych celów.",
            features: [
                OnboardingFeature(icon: "lock.shield.fill", text: "Dane przetwarzane lokalnie"),
                OnboardingFeature(icon: "trash.fill", text: "Nic nie jest wysyłane na serwery"),
                OnboardingFeature(icon: "gamecontroller.fill", text: "Stworzony tylko dla zabawy")
            ]
        )
    ]

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.15),
                    Color(red: 0.1, green: 0.12, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Animated background particles
            ParticlesView()
                .opacity(0.3)

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 10)
                }

                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Capsule()
                            .fill(currentPage == index ? Color.cyan : Color.white.opacity(0.3))
                            .frame(width: currentPage == index ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Navigation buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: {
                            withAnimation {
                                currentPage -= 1
                            }
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.left")
                                Text("button.back".localized)
                            }
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 18) // Increased from 14 to 18 for 44pt min touch target
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                            )
                        }
                    }

                    Spacer()

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            dismiss()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(currentPage < pages.count - 1 ? "button.next".localized : "onboarding.start".localized)
                            Image(systemName: currentPage < pages.count - 1 ? "chevron.right" : "arrow.right")
                        }
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 18) // Increased from 14 to 18 for 44pt min touch target
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: currentPage < pages.count - 1 ?
                                            [Color.cyan, Color.blue] :
                                            [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: (currentPage < pages.count - 1 ? Color.cyan : Color.green).opacity(0.4), radius: 15, y: 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

// MARK: - Onboarding Page Model

struct OnboardingPage {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let description: String
    let features: [OnboardingFeature]
}

struct OnboardingFeature {
    let icon: String
    let text: String
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Animated icon
            ZStack {
                // Glow effect
                Circle()
                    .fill(page.iconColor.opacity(0.2))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)
                    .scaleEffect(isAnimating ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [page.iconColor.opacity(0.3), page.iconColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [page.iconColor, page.iconColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.6),
                        value: isAnimating
                    )
            }

            // Title section
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(page.iconColor)
                    .multilineTextAlignment(.center)
            }

            // Description
            Text(page.description)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // Features list
            if !page.features.isEmpty {
                VStack(spacing: 12) {
                    ForEach(page.features.indices, id: \.self) { index in
                        OnboardingFeatureRow(feature: page.features[index], color: page.iconColor)
                            .opacity(isAnimating ? 1 : 0)
                            .offset(x: isAnimating ? 0 : -20)
                            .animation(
                                .easeOut(duration: 0.5).delay(Double(index) * 0.1),
                                value: isAnimating
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isAnimating = true
            }
        }
        .onDisappear {
            isAnimating = false
        }
    }
}

// MARK: - Feature Row

struct OnboardingFeatureRow: View {
    let feature: OnboardingFeature
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(color.opacity(0.15))
                )

            Text(feature.text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Particles View

struct ParticlesView: View {
    @State private var particles: [Particle] = []

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .blur(radius: particle.size / 4)
                }
            }
            .onAppear {
                generateParticles(in: geo.size)
            }
        }
    }

    private func generateParticles(in size: CGSize) {
        particles = (0..<15).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                size: CGFloat.random(in: 20...80),
                color: ([Color.cyan, Color.blue, Color.purple, Color.teal].randomElement() ?? .cyan).opacity(0.3)
            )
        }
    }
}

struct Particle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var size: CGFloat
    var color: Color
}

// MARK: - Preview

#Preview {
    OnboardingView()
}
