//
//  CalibrationQuestionView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// View showing the calibration question and listening for answer
struct CalibrationQuestionView: View {
    let coordinator: CalibrationCoordinator
    
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Question text
                if let question = coordinator.currentQuestion {
                    Text(question.text)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0)
                }
                
                Spacer()
                
                // Recording indicator
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: pulseScale
                            )
                        
                        Text("Słucham...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    // Recognized text display (for debugging/feedback)
                    if !coordinator.speechService.recognizedText.isEmpty {
                        Text(coordinator.speechService.recognizedText)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 40)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
            pulseScale = 1.2
        }
    }
}

// MARK: - Completion View

struct CalibrationCompleteView: View {
    let coordinator: CalibrationCoordinator
    let player: Player
    let onFinish: () -> Void
    
    @State private var isAnimating = false
    @State private var showConfetti = false
    
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
                
                // Success animation
                ZStack {
                    // Expanding circles
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 3)
                            .frame(width: 100 + CGFloat(index) * 40, height: 100 + CGFloat(index) * 40)
                            .scaleEffect(isAnimating ? 1.5 : 1.0)
                            .opacity(isAnimating ? 0 : 1)
                            .animation(
                                .easeOut(duration: 1.5)
                                .delay(Double(index) * 0.2),
                                value: isAnimating
                            )
                    }
                    
                    Text("✅")
                        .font(.system(size: 100))
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .rotationEffect(.degrees(isAnimating ? 0 : -180))
                }
                
                VStack(spacing: 16) {
                    Text("Kalibracja ukończona!")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Poznaliśmy Twoje naturalne reakcje")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                // Stats
                VStack(spacing: 16) {
                    StatRow(
                        icon: "checkmark.circle.fill",
                        label: "Odpowiedzi",
                        value: "\(coordinator.questionResponses.count)/\(coordinator.questions.count)"
                    )
                    
                    StatRow(
                        icon: "brain.head.profile",
                        label: "Bazowe dane",
                        value: "Zebrane"
                    )
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Finish button
                Button(action: {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    onFinish()
                }) {
                    Text("Zakończ")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.green.opacity(0.5), radius: 20, y: 10)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.cyan)
                .frame(width: 40)
            
            Text(label)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.1))
        )
    }
}

#Preview("Question") {
    CalibrationQuestionView(
        coordinator: CalibrationCoordinator(player: Player(name: "Jan", age: 25, gender: .male))
    )
}

#Preview("Complete") {
    CalibrationCompleteView(
        coordinator: CalibrationCoordinator(player: Player(name: "Jan", age: 25, gender: .male)),
        player: Player(name: "Jan", age: 25, gender: .male),
        onFinish: {}
    )
}
