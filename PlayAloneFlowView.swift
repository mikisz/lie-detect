//
//  PlayAloneFlowView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

// MARK: - Setup Flow Step

enum PlayAloneSetupStep {
    case selectPlayer
    case selectPack
    case selectCount
    case selectMode
    case manualSelection
    case playing
}

/// Main view for solo play mode
struct PlayAloneFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var players: [Player]

    // Flow state
    @State private var currentStep: PlayAloneSetupStep = .selectPlayer
    @State private var selectedPlayer: Player?
    @State private var selectedPack: QuestionPack?
    @State private var selectedQuestionCount: Int = 10
    @State private var selectedSelectionMode: QuestionSelectionMode = .random
    @State private var selectedVerdictMode: VerdictMode = .afterEach
    @State private var gameSession: GameSession?

    var body: some View {
        Group {
            switch currentStep {
            case .selectPlayer:
                PlayerSelectionView(players: calibratedPlayers) { player in
                    selectedPlayer = player
                    currentStep = .selectPack
                } onCancel: {
                    dismiss()
                }

            case .selectPack:
                PackSelectionView(
                    packs: QuestionPackManager.shared.getAllPacks(),
                    onSelect: { pack in
                        selectedPack = pack
                        currentStep = .selectCount
                    },
                    onCancel: {
                        if calibratedPlayers.count == 1 {
                            dismiss()
                        } else {
                            currentStep = .selectPlayer
                        }
                    }
                )

            case .selectCount:
                QuestionCountSelector(
                    pack: selectedPack!,
                    selectedCount: $selectedQuestionCount,
                    onContinue: {
                        currentStep = .selectMode
                    },
                    onBack: {
                        currentStep = .selectPack
                    }
                )

            case .selectMode:
                SelectionModeView(
                    pack: selectedPack!,
                    questionCount: selectedQuestionCount,
                    selectionMode: $selectedSelectionMode,
                    verdictMode: $selectedVerdictMode,
                    onContinue: {
                        if selectedSelectionMode == .manual {
                            currentStep = .manualSelection
                        } else {
                            startGameWithConfiguration(selectedQuestionIds: nil)
                        }
                    },
                    onBack: {
                        currentStep = .selectCount
                    }
                )

            case .manualSelection:
                ManualQuestionSelectionView(
                    pack: selectedPack!,
                    requiredCount: selectedQuestionCount,
                    onConfirm: { selectedIds in
                        startGameWithConfiguration(selectedQuestionIds: selectedIds)
                    },
                    onBack: {
                        currentStep = .selectMode
                    }
                )

            case .playing:
                if let session = gameSession {
                    GameSessionView(session: session) {
                        gameSession = nil
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            // Auto-select if only one calibrated player
            if calibratedPlayers.count == 1 {
                selectedPlayer = calibratedPlayers.first
                currentStep = .selectPack
            }
        }
    }

    private var calibratedPlayers: [Player] {
        players.filter { $0.isCalibrated }
    }

    private func startGameWithConfiguration(selectedQuestionIds: [String]?) {
        guard let player = selectedPlayer, let pack = selectedPack else { return }

        let configuration = GameConfiguration(
            pack: pack,
            questionCount: selectedQuestionCount,
            selectionMode: selectedSelectionMode,
            verdictMode: selectedVerdictMode,
            selectedQuestionIds: selectedQuestionIds
        )

        let questions = configuration.getGameQuestions()

        let session = GameSession(
            player: player,
            questions: questions,
            sessionType: .solo,
            verdictMode: selectedVerdictMode
        )

        gameSession = session
        currentStep = .playing
        session.startSession()
        AudioService.shared.playGameMusic()
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

                    Text("player.select.title".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)

                    Text("player.select.subtitle".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)

                if players.isEmpty {
                    // No calibrated players
                    VStack(spacing: 20) {
                        Text("❌")
                            .font(.system(size: 60))

                        Text("player.select.no_players".localized)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)

                        Text("player.select.no_players_hint".localized)
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
                        Text("player.age_years".localized(with: player.age))
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }

                Spacer()

                // Calibration badge
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("player.calibrated".localized)
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

#Preview {
    PlayAloneFlowView()
        .modelContainer(for: [Player.self], inMemory: true)
}
