//
//  ContentView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var players: [Player]

    @State private var hasCompletedOnboarding = false
    @State private var isCheckingPlayers = true
    @State private var newPlayerToCalibrate: Player?

    var body: some View {
        Group {
            if isCheckingPlayers {
                // Loading state
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

                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            } else if players.isEmpty {
                // No players - show onboarding (works for first launch AND after all players deleted)
                CreatePlayerView(isFirstPlayer: true) { player in
                    // After first player is created, launch calibration
                    hasCompletedOnboarding = true
                    newPlayerToCalibrate = player
                }
            } else {
                // Normal app flow
                MainMenuView()
            }
        }
        .fullScreenCover(item: $newPlayerToCalibrate) { player in
            CalibrationFlowView(player: player) {
                newPlayerToCalibrate = nil
            }
        }
        .onAppear {
            // Small delay to check for players
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isCheckingPlayers = false
            }
        }
        .onChange(of: players.count) { oldCount, newCount in
            // Reset onboarding flag when all players are deleted
            if newCount == 0 {
                hasCompletedOnboarding = false
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Player.self], inMemory: true)
}
