//
//  CalibrationFlowView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI
import SwiftData

/// Main view that coordinates the entire calibration flow
struct CalibrationFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let player: Player
    var onComplete: (() -> Void)?
    
    @State private var coordinator: CalibrationCoordinator
    
    init(player: Player, onComplete: (() -> Void)? = nil) {
        self.player = player
        self.onComplete = onComplete
        _coordinator = State(initialValue: CalibrationCoordinator(player: player))
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            // Phase-specific content
            Group {
                switch coordinator.currentPhase {
                case .intro:
                    CalibrationIntroView(coordinator: coordinator)
                        .transition(.opacity)
                    
                case .prepare:
                    CalibrationPrepareView(coordinator: coordinator)
                        .transition(.opacity)
                    
                case .countdown:
                    CalibrationCountdownView()
                        .transition(.opacity)
                    
                case .question:
                    CalibrationQuestionView(coordinator: coordinator)
                        .transition(.opacity)
                    
                case .complete:
                    CalibrationCompleteView(coordinator: coordinator, player: player) {
                        saveCalibrationAndDismiss()
                    }
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: coordinator.currentPhase)
        }
        .onAppear {
            coordinator.faceTrackingService.startTracking()
            coordinator.startCalibration()
        }
        .onDisappear {
            coordinator.cleanup()
        }
    }
    
    private func saveCalibrationAndDismiss() {
        if let calibrationData = coordinator.finishCalibration() {
            player.calibrationData = calibrationData
            player.lastCalibratedAt = Date()
            
            // Haptic success feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            
            print("✅ Saved calibration data for \(player.name)")
        }
        
        onComplete?()
        dismiss()
    }
}

// MARK: - Intro View

struct CalibrationIntroView: View {
    let coordinator: CalibrationCoordinator
    
    @State private var isAnimating = false
    
    var body: some View {
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
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                Text("🎯")
                    .font(.system(size: 100))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                
                VStack(spacing: 20) {
                    Text("Kalibracja")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Za chwilę odpowiesz na \(coordinator.questions.count) prostych pytań")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    InstructionRow(icon: "checkmark.circle.fill", text: "Odpowiadaj zawsze prawdą", color: .green)
                    InstructionRow(icon: "eye.fill", text: "Patrz prosto w kamerę", color: .cyan)
                    InstructionRow(icon: "mic.fill", text: "Mów wyraźnie 'tak' lub 'nie'", color: .cyan)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    coordinator.proceedToNextQuestion()
                }) {
                    Text("Rozpocznij kalibrację")
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
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct InstructionRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    CalibrationFlowView(
        player: Player(name: "Jan", age: 25, gender: .male)
    )
    .modelContainer(for: [Player.self], inMemory: true)
}
