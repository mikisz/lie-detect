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
                                title: "Graj Solo",
                                subtitle: "Przetestuj się sam",
                                gradient: [Color.blue, Color.cyan]
                            ) {
                                showPlayAlone = true
                            }
                            
                            MenuButton(
                                icon: "person.3.fill",
                                title: "Gorące Krzesło",
                                subtitle: "Graj z przyjaciółmi",
                                gradient: [Color.orange, Color.red]
                            ) {
                                showHotSeat = true
                            }
                            
                            MenuButton(
                                icon: "wifi",
                                title: "Graj Online",
                                subtitle: "Wkrótce...",
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
                                title: "Gracze"
                            ) {
                                showPlayers = true
                            }
                            
                            SecondaryMenuButton(
                                icon: "lightbulb.fill",
                                title: "Jak to działa?"
                            ) {
                                showTutorial = true
                            }
                            
                            SecondaryMenuButton(
                                icon: "gearshape.fill",
                                title: "Ustawienia"
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
                Text("Players List - Coming Soon")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showTutorial) {
                TutorialView()
            }
            .fullScreenCover(isPresented: $showPlayAlone) {
                ComingSoonView(title: "Graj Solo", message: "Tryb solo będzie dostępny wkrótce!")
            }
            .fullScreenCover(isPresented: $showHotSeat) {
                ComingSoonView(title: "Gorące Krzesło", message: "Tryb multiplayer będzie dostępny wkrótce!")
            }
        }
        .onAppear {
            isAnimating = true
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
            .shadow(color: isDisabled ? .clear : gradient.first!.opacity(0.3), radius: 20, y: 10)
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
                    Text("Zamknij")
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.1, blue: 0.2).ignoresSafeArea()
                
                Text("Ustawienia")
                    .font(.title)
                    .foregroundColor(.white)
            }
            .navigationTitle("Ustawienia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct TutorialView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.1, blue: 0.2).ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("🎭")
                            .font(.system(size: 80))
                            .frame(maxWidth: .infinity)
                        
                        Text("Jak to działa?")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        TutorialSection(
                            icon: "camera.fill",
                            title: "Kalibracja",
                            description: "Najpierw odpowiesz na kilka prostych pytań prawdą. To pozwoli nam poznać Twoje naturalne reakcje."
                        )
                        
                        TutorialSection(
                            icon: "face.smiling.fill",
                            title: "Analiza twarzy",
                            description: "Kamera śledzi mikro-ekspresje, mruganie i kierunek spojrzenia podczas odpowiedzi."
                        )
                        
                        TutorialSection(
                            icon: "waveform",
                            title: "Odpowiedzi głosowe",
                            description: "Mów 'tak' lub 'nie' - aplikacja rozpoznaje Twoją odpowiedź automatycznie."
                        )
                        
                        TutorialSection(
                            icon: "exclamationmark.triangle.fill",
                            title: "To tylko gra!",
                            description: "Lie Detect to zabawna gra, nie profesjonalny detektor kłamstw. Wszystkie dane są przetwarzane lokalnie i nie są przechowywane."
                        )
                        
                        Text("Wskazówki dla najlepszych wyników:")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.top, 12)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            TipRow(text: "Graj w dobrze oświetlonym pomieszczeniu")
                            TipRow(text: "Patrz prosto w kamerę")
                            TipRow(text: "Bądź naturalny i zrelaksowany")
                            TipRow(text: "Mów wyraźnie 'tak' lub 'nie'")
                        }
                    }
                    .padding(24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Zamknij") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct TutorialSection: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.cyan)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct TipRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

#Preview {
    MainMenuView()
        .modelContainer(for: [Player.self], inMemory: true)
}
