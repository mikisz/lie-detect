//
//  HotSeatFlowView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

/// Main view for Hot Seat multiplayer mode
struct HotSeatFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]
    
    @State private var selectedPlayers: [Player] = []
    @State private var selectedPack: GamePack?
    @State private var hotSeatSession: HotSeatSession?
    @State private var setupStep: HotSeatSetupStep = .playerSelection
    
    var body: some View {
        Group {
            if let session = hotSeatSession {
                // Game in progress
                HotSeatGameView(session: session) {
                    // On complete
                    hotSeatSession = nil
                    dismiss()
                }
            } else {
                // Setup flow
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    switch setupStep {
                    case .playerSelection:
                        HotSeatPlayerSelectionView(
                            players: calibratedPlayers,
                            selectedPlayers: $selectedPlayers
                        ) {
                            if selectedPlayers.count >= 2 {
                                setupStep = .packSelection
                            }
                        } onCancel: {
                            dismiss()
                        }
                        .transition(.opacity)
                        
                    case .packSelection:
                        HotSeatPackSelectionView(
                            playerCount: selectedPlayers.count,
                            selectedPack: $selectedPack
                        ) { pack in
                            startHotSeatGame(with: pack)
                        } onBack: {
                            setupStep = .playerSelection
                        }
                        .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: setupStep)
            }
        }
    }
    
    private var calibratedPlayers: [Player] {
        players.filter { $0.isCalibrated }
    }
    
    private func startHotSeatGame(with pack: GamePack) {
        let questionsPerPlayer = pack.questionCount / selectedPlayers.count
        let totalQuestions = questionsPerPlayer * selectedPlayers.count
        let questions = Array(pack.questions.shuffled().prefix(totalQuestions))
        
        let session = HotSeatSession(
            players: selectedPlayers,
            questions: questions,
            questionsPerPlayer: questionsPerPlayer
        )
        
        hotSeatSession = session
        session.startSession()
    }
}

// MARK: - Setup Steps

enum HotSeatSetupStep {
    case playerSelection
    case packSelection
}

// MARK: - Player Selection View

struct HotSeatPlayerSelectionView: View {
    let players: [Player]
    @Binding var selectedPlayers: [Player]
    let onContinue: () -> Void
    let onCancel: () -> Void
    
    @State private var isAnimating = false
    @Environment(\.audioService) private var audioService
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.05, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 70))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("hotseat.select_players".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("hotseat.min_players".localized(2))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                    
                    // Selected count
                    Text("hotseat.selected_count".localized(selectedPlayers.count))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.top, 8)
                }
                .padding(.top, 60)
                
                if players.isEmpty {
                    // No calibrated players
                    VStack(spacing: 20) {
                        Text("❌")
                            .font(.system(size: 60))
                        
                        Text("empty.no_calibrated".localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("empty.no_calibrated_message".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 40)
                } else {
                    // Player grid
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 16) {
                            ForEach(players) { player in
                                HotSeatPlayerCard(
                                    player: player,
                                    isSelected: selectedPlayers.contains(where: { $0.id == player.id })
                                ) {
                                    togglePlayer(player)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        audioService.playSound(.success)
                        onContinue()
                    }) {
                        Text("button.continue".localized)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedPlayers.count >= 2 ?
                                        LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .shadow(color: selectedPlayers.count >= 2 ? Color.orange.opacity(0.5) : .clear, radius: 20, y: 10)
                    }
                    .disabled(selectedPlayers.count < 2)
                    
                    Button(action: {
                        audioService.playSound(.buttonTap)
                        onCancel()
                    }) {
                        Text("button.cancel".localized)
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
    
    private func togglePlayer(_ player: Player) {
        audioService.playSound(.buttonTap)
        
        if let index = selectedPlayers.firstIndex(where: { $0.id == player.id }) {
            selectedPlayers.remove(at: index)
        } else {
            selectedPlayers.append(player)
        }
    }
}

// MARK: - Player Card

struct HotSeatPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [Color.orange, Color.red] : [Color.gray, Color.gray.opacity(0.5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    if isSelected {
                        Circle()
                            .stroke(Color.orange, lineWidth: 3)
                            .frame(width: 70, height: 70)
                    }
                    
                    Text(player.initials)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Name
                Text(player.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                // Checkmark
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isSelected)
        }
    }
}

// MARK: - Pack Selection View

struct HotSeatPackSelectionView: View {
    let playerCount: Int
    @Binding var selectedPack: GamePack?
    let onStart: (GamePack) -> Void
    let onBack: () -> Void
    
    @State private var isAnimating = false
    @Environment(\.audioService) private var audioService
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.1, blue: 0.15),
                    Color(red: 0.15, green: 0.05, blue: 0.2)
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
                    
                    Text("game.select_pack".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("hotseat.pack_info".localized(playerCount))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
                
                // Pack selection
                VStack(spacing: 16) {
                    ForEach(GamePack.allCases, id: \.self) { pack in
                        HotSeatPackCard(
                            pack: pack,
                            playerCount: playerCount,
                            isSelected: selectedPack == pack
                        ) {
                            audioService.playSound(.buttonTap)
                            selectedPack = pack
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        if let pack = selectedPack {
                            audioService.playSound(.success)
                            onStart(pack)
                        }
                    }) {
                        Text("button.start_game".localized)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        selectedPack != nil ?
                                        LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing) :
                                        LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                    )
                            )
                            .shadow(color: selectedPack != nil ? Color.orange.opacity(0.5) : .clear, radius: 20, y: 10)
                    }
                    .disabled(selectedPack == nil)
                    
                    Button(action: {
                        audioService.playSound(.buttonTap)
                        onBack()
                    }) {
                        Text("general.back".localized)
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

// MARK: - Pack Card

struct HotSeatPackCard: View {
    let pack: GamePack
    let playerCount: Int
    let isSelected: Bool
    let action: () -> Void
    
    var questionsPerPlayer: Int {
        pack.questionCount / playerCount
    }
    
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
                    
                    Text("hotseat.questions_per_player".localized(questionsPerPlayer))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color.orange : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    HotSeatFlowView()
        .modelContainer(for: [Player.self], inMemory: true)
}
