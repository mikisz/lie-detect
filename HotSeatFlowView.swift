//
//  HotSeatFlowView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

// MARK: - Setup Steps

enum HotSeatSetupStep {
    case playerSelection
    case packSelection
    case countSelection
    case modeSelection
    case manualSelection
    case playing
}

/// Main view for Hot Seat multiplayer mode
struct HotSeatFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]

    // Flow state
    @State private var setupStep: HotSeatSetupStep = .playerSelection
    @State private var selectedPlayers: [Player] = []
    @State private var selectedPack: QuestionPack?
    @State private var selectedQuestionCount: Int = 10
    @State private var selectedSelectionMode: QuestionSelectionMode = .random
    @State private var selectedVerdictMode: VerdictMode = .afterEach
    @State private var hotSeatSession: HotSeatSession?

    var body: some View {
        Group {
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

            case .packSelection:
                PackSelectionView(
                    packs: QuestionPackManager.shared.getAllPacks(),
                    onSelect: { pack in
                        selectedPack = pack
                        setupStep = .countSelection
                    },
                    onCancel: {
                        setupStep = .playerSelection
                    }
                )

            case .countSelection:
                HotSeatQuestionCountSelector(
                    pack: selectedPack!,
                    playerCount: selectedPlayers.count,
                    selectedCount: $selectedQuestionCount,
                    onContinue: {
                        setupStep = .modeSelection
                    },
                    onBack: {
                        setupStep = .packSelection
                    }
                )

            case .modeSelection:
                SelectionModeView(
                    pack: selectedPack!,
                    questionCount: selectedQuestionCount,
                    selectionMode: $selectedSelectionMode,
                    verdictMode: $selectedVerdictMode,
                    onContinue: {
                        if selectedSelectionMode == .manual {
                            setupStep = .manualSelection
                        } else {
                            startHotSeatGame(selectedQuestionIds: nil)
                        }
                    },
                    onBack: {
                        setupStep = .countSelection
                    }
                )

            case .manualSelection:
                ManualQuestionSelectionView(
                    pack: selectedPack!,
                    requiredCount: selectedQuestionCount,
                    onConfirm: { selectedIds in
                        startHotSeatGame(selectedQuestionIds: selectedIds)
                    },
                    onBack: {
                        setupStep = .modeSelection
                    }
                )

            case .playing:
                if let session = hotSeatSession {
                    HotSeatGameView(session: session) {
                        hotSeatSession = nil
                        dismiss()
                    }
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: setupStep)
    }

    private var calibratedPlayers: [Player] {
        players.filter { $0.isCalibrated }
    }

    private func startHotSeatGame(selectedQuestionIds: [String]?) {
        guard let pack = selectedPack else { return }

        let configuration = GameConfiguration(
            pack: pack,
            questionCount: selectedQuestionCount,
            selectionMode: selectedSelectionMode,
            verdictMode: selectedVerdictMode,
            selectedQuestionIds: selectedQuestionIds
        )

        let questions = configuration.getGameQuestions()
        let questionsPerPlayer = selectedQuestionCount / selectedPlayers.count

        let session = HotSeatSession(
            players: selectedPlayers,
            questions: questions,
            questionsPerPlayer: questionsPerPlayer,
            verdictMode: selectedVerdictMode
        )

        hotSeatSession = session
        setupStep = .playing
        session.startSession()
        AudioService.shared.playGameMusic()
    }
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

// MARK: - Hot Seat Question Count Selector

struct HotSeatQuestionCountSelector: View {
    let pack: QuestionPack
    let playerCount: Int
    @Binding var selectedCount: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isAnimating = false

    private let countOptions = [6, 10, 15]

    var body: some View {
        ZStack {
            // Background
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
                    Text("🔢")
                        .font(.system(size: 70))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                    Text("game.setup.how_many".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("hotseat.pack_info".localized(with: playerCount))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)

                // Count selection
                HStack(spacing: 16) {
                    ForEach(countOptions, id: \.self) { count in
                        let questionsPerPlayer = count / playerCount
                        let isDisabled = count > pack.questionCount || questionsPerPlayer < 1

                        Button(action: {
                            if !isDisabled {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                selectedCount = count
                            }
                        }) {
                            VStack(spacing: 8) {
                                Text("\(count)")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(isDisabled ? .white.opacity(0.3) : (selectedCount == count ? .orange : .white))

                                Text("game.setup.questions".localized)
                                    .font(.system(size: 12))
                                    .foregroundColor(isDisabled ? .white.opacity(0.2) : .white.opacity(0.6))

                                if !isDisabled {
                                    Text("hotseat.per_player".localized(with: questionsPerPlayer))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.orange.opacity(0.8))
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(isDisabled ? Color.white.opacity(0.03) : (selectedCount == count ? Color.orange.opacity(0.15) : Color.white.opacity(0.08)))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(
                                        isDisabled ? Color.white.opacity(0.1) : (selectedCount == count ? Color.orange : Color.white.opacity(0.2)),
                                        lineWidth: selectedCount == count ? 2 : 1
                                    )
                            )
                        }
                        .disabled(isDisabled)
                    }
                }
                .padding(.horizontal, 24)

                // Pack info
                VStack(spacing: 8) {
                    Text(pack.localizedName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text("game.setup.available_questions".localized(with: pack.questionCount))
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 20)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
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
                                        LinearGradient(
                                            colors: [Color.orange, Color.red],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.orange.opacity(0.5), radius: 20, y: 10)
                    }

                    Button(action: onBack) {
                        Text("button.back".localized)
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
            // Set default to first valid option
            for count in countOptions {
                let questionsPerPlayer = count / playerCount
                if count <= pack.questionCount && questionsPerPlayer >= 1 {
                    selectedCount = count
                    break
                }
            }
        }
    }
}

#Preview {
    HotSeatFlowView()
        .modelContainer(for: [Player.self], inMemory: true)
}
