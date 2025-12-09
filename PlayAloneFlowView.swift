//
//  PlayAloneFlowView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

/// Main view for solo play mode
struct PlayAloneFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    
    @State private var selectedPlayer: Player?
    @State private var gameSession: GameSession?
    @State private var showingPlayerPicker = false
    
    var body: some View {
        Group {
            if let session = gameSession {
                // Game in progress
                GameSessionView(session: session) {
                    // On complete
                    gameSession = nil
                    dismiss()
                }
            } else if selectedPlayer != nil {
                // Player selected, show game setup
                GameSetupView(player: selectedPlayer!) { questionPack in
                    startGame(with: questionPack)
                } onCancel: {
                    selectedPlayer = nil
                }
            } else {
                // No player selected - show picker
                PlayerSelectionView(players: calibratedPlayers) { player in
                    selectedPlayer = player
                } onCancel: {
                    dismiss()
                }
            }
        }
        .onAppear {
            // Auto-select if only one calibrated player
            if calibratedPlayers.count == 1 {
                selectedPlayer = calibratedPlayers.first
            }
        }
    }
    
    private var calibratedPlayers: [Player] {
        players.filter { $0.isCalibrated }
    }
    
    private func startGame(with questions: [GameQuestion]) {
        guard let player = selectedPlayer else { return }
        
        let session = GameSession(
            player: player,
            questions: questions,
            sessionType: .solo
        )
        
        gameSession = session
        session.startSession()
    }
}

// MARK: - Player Selection View

struct PlayerSelectionView: View {
    let players: [Player]
    let onSelect: (Player) -> Void
    let onCancel: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("🎯")
                        .font(.system(size: 70))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Wybierz gracza")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Tylko skalibrowane profile")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)
                
                if players.isEmpty {
                    // No calibrated players
                    VStack(spacing: 20) {
                        Text("❌")
                            .font(.system(size: 60))
                        
                        Text("Brak skalibrowanych graczy")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Najpierw ukończ kalibrację w sekcji Gracze")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                } else {
                    // Player list
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(players) { player in
                                PlayAlonePlayerCard(player: player) {
                                    onSelect(player)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Cancel button
                Button(action: onCancel) {
                    Text("Anuluj")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PlayAlonePlayerCard: View {
    let player: Player
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: 16) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Text(player.initials)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 8) {
                        Text(player.gender.emoji)
                        Text("\(player.age) lat")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Calibration badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Skalibrowany")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.green.opacity(0.2))
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
        }
    }
}

// MARK: - Game Setup View

struct GameSetupView: View {
    let player: Player
    let onStart: ([GameQuestion]) -> Void
    let onCancel: () -> Void
    
    @State private var selectedPack: GamePack = .standard
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("🎲")
                        .font(.system(size: 70))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Wybierz pakiet pytań")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Gracz: \(player.name)")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)
                
                // Pack selection
                VStack(spacing: 16) {
                    ForEach(GamePack.allCases, id: \.self) { pack in
                        PackCard(
                            pack: pack,
                            isSelected: selectedPack == pack
                        ) {
                            selectedPack = pack
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let questions = selectedPack.questions
                        onStart(questions)
                    }) {
                        Text("Rozpocznij grę")
                            .font(.system(size: 20, weight: .bold))
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
                            .shadow(color: Color.cyan.opacity(0.5), radius: 20, y: 10)
                    }
                    
                    Button(action: onCancel) {
                        Text("Anuluj")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct PackCard: View {
    let pack: GamePack
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(pack.emoji)
                    .font(.system(size: 40))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(pack.description)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(pack.questionCount) pytań")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.cyan)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

// MARK: - Game Pack Enum

enum GamePack: CaseIterable {
    case quick
    case standard
    case extended
    case spicy
    
    var name: String {
        switch self {
        case .quick: return "Szybka gra"
        case .standard: return "Standard"
        case .extended: return "Rozszerzona"
        case .spicy: return "Pikantna 🌶️"
        }
    }
    
    var description: String {
        switch self {
        case .quick: return "5 pytań na szybko"
        case .standard: return "10 różnorodnych pytań"
        case .extended: return "15 pytań - pełna sesja"
        case .spicy: return "10 odważnych pytań"
        }
    }
    
    var questionCount: Int {
        switch self {
        case .quick: return 5
        case .standard: return 10
        case .extended: return 15
        case .spicy: return 10
        }
    }
    
    var emoji: String {
        switch self {
        case .quick: return "⚡"
        case .standard: return "🎯"
        case .extended: return "🎪"
        case .spicy: return "🌶️"
        }
    }
    
    var questions: [GameQuestion] {
        switch self {
        case .quick: return GameQuestionGenerator.getQuickGamePack()
        case .standard: return GameQuestionGenerator.getStandardGamePack()
        case .extended: return GameQuestionGenerator.getExtendedGamePack()
        case .spicy: return GameQuestionGenerator.getSpicyGamePack()
        }
    }
}

#Preview {
    PlayAloneFlowView()
        .modelContainer(for: [Player.self], inMemory: true)
}
