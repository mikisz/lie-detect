//
//  PlayersListView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

struct PlayersListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Player.createdAt, order: .reverse) private var players: [Player]

    @State private var showAddPlayer = false
    @State private var selectedPlayerId: UUID?
    @State private var playerToCalibrate: Player?
    @State private var showCalibration = false
    @State private var playerToDelete: Player?
    @State private var showDeleteConfirmation = false
    @State private var isPreparingCalibration = false

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

            if players.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Text("👥")
                        .font(.system(size: 80))

                    Text("players.no_players".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("players.add_first".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)

                    Button(action: { showAddPlayer = true }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("player.create".localized)
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
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
                    }
                    .padding(.top, 8)
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(players) { player in
                            NavigationLink(value: player.id) {
                                PlayerCard(player: player)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                Button(role: .destructive) {
                                    playerToDelete = player
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("button.delete".localized, systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    playerToDelete = player
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("button.delete".localized, systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }

            // Loading overlay for calibration preparation
            if isPreparingCalibration {
                Color.black.opacity(0.6)
                    .ignoresSafeArea()
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    Text("players.preparing".localized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .navigationTitle("players.title".localized)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showAddPlayer = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
        }
        .sheet(isPresented: $showAddPlayer) {
            CreatePlayerView(isFirstPlayer: false) { newPlayer in
                // After player is created, trigger calibration
                showAddPlayer = false
                isPreparingCalibration = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    playerToCalibrate = newPlayer
                    isPreparingCalibration = false
                    showCalibration = true
                }
            }
        }
        .fullScreenCover(isPresented: $showCalibration) {
            if let player = playerToCalibrate {
                CalibrationFlowView(player: player) {
                    showCalibration = false
                    playerToCalibrate = nil
                }
            }
        }
        .navigationDestination(for: UUID.self) { playerId in
            if let player = players.first(where: { $0.id == playerId }) {
                PlayerDetailView(player: player)
            } else {
                Text("players.not_found".localized)
                    .foregroundColor(.white)
            }
        }
        .confirmationDialog(
            "player.delete_confirm_title".localized,
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("player.delete_player".localized, role: .destructive) {
                if let player = playerToDelete {
                    modelContext.delete(player)
                    playerToDelete = nil
                }
            }
            Button("button.cancel".localized, role: .cancel) {
                playerToDelete = nil
            }
        } message: {
            Text("player.delete_confirm_message".localized)
        }
    }
}

struct PlayerCard: View {
    let player: Player
    
    @State private var isPressed = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: player.isCalibrated ?
                                [Color.green, Color.teal] :
                                [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                if let imageData = player.profileImageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 70, height: 70)
                        .clipShape(Circle())
                } else {
                    Text(player.initials)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
            )
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(player.name)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
                
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text(player.gender.emoji)
                            .font(.system(size: 14))
                        Text("player.years".localized(with: player.age))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }

                    CalibrationBadge(isCalibrated: player.isCalibrated)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct CalibrationBadge: View {
    let isCalibrated: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isCalibrated ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 12))

            Text(isCalibrated ? "player.calibrated".localized : "player.requires_calibration".localized)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundColor(isCalibrated ? .green : .orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((isCalibrated ? Color.green : Color.orange).opacity(0.2))
        )
    }
}

#Preview {
    NavigationStack {
        PlayersListView()
            .modelContainer(for: [Player.self], inMemory: true)
    }
}
