//
//  GameSessionView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// Main view that coordinates the game session phases
struct GameSessionView: View {
    let session: GameSession
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Group {
                switch session.currentPhase {
                case .intro:
                    GameIntroView(session: session)
                        .transition(.opacity)
                    
                case .prepare:
                    GamePrepareView(session: session)
                        .transition(.opacity)
                    
                case .countdown:
                    GameCountdownView()
                        .transition(.opacity)
                    
                case .question:
                    GameQuestionView(session: session)
                        .transition(.opacity)
                    
                case .verdict:
                    if let lastResult = session.questionResults.last {
                        GameVerdictView(result: lastResult, session: session)
                            .transition(.opacity)
                    }
                    
                case .sessionComplete:
                    GameCompleteView(session: session, onDismiss: onComplete)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: session.currentPhase)
        }
        .onDisappear {
            session.cleanup()
        }
    }
}

// MARK: - Game Intro

struct GameIntroView: View {
    let session: GameSession
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.3), Color.cyan.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Text("🎮")
                    .font(.system(size: 100))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 16) {
                    Text("Rozpoczynamy!")
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Gracz: \(session.player.name)")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("\(session.questions.count) pytań")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 Pamiętaj:")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    InstructionRow(icon: "checkmark.circle.fill", text: "Odpowiadaj prawdę lub kłam celowo", color: .green)
                    InstructionRow(icon: "eye.fill", text: "Patrz prosto w kamerę", color: .cyan)
                    InstructionRow(icon: "mic.fill", text: "Mów wyraźnie 'tak' lub 'nie'", color: .cyan)
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    session.proceedToNextQuestion()
                }) {
                    Text("Start")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
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

// MARK: - Game Prepare View

struct GamePrepareView: View {
    let session: GameSession
    @State private var isAnimating = false
    
    var faceQuality: FaceQuality {
        session.faceTrackingService.faceQuality
    }
    
    var isFaceDetected: Bool {
        session.faceTrackingService.isFaceDetected
    }
    
    var canProceed: Bool {
        isFaceDetected && faceQuality == .good
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Progress
                VStack(spacing: 8) {
                    Text("Pytanie \(session.currentQuestionIndex + 1) z \(session.questions.count)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ProgressView(value: session.progress)
                        .tint(.cyan)
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Face quality indicator
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 8)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .fill(qualityColor.opacity(0.3))
                            .frame(width: 150, height: 150)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text(faceQuality.emoji)
                            .font(.system(size: 60))
                    }
                    
                    Text(faceQuality.message)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Ready button
                Button(action: {
                    session.startQuestionRecording()
                }) {
                    Text("Jestem gotowy")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    canProceed ?
                                    LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .shadow(color: canProceed ? Color.cyan.opacity(0.5) : .clear, radius: 20, y: 10)
                }
                .disabled(!canProceed)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var qualityColor: Color {
        switch faceQuality {
        case .unknown: return .gray
        case .poor: return .red
        case .fair: return .orange
        case .good: return .green
        }
    }
}

extension FaceQuality {
    var emoji: String {
        switch self {
        case .unknown: return "❓"
        case .poor: return "❌"
        case .fair: return "⚠️"
        case .good: return "✅"
        }
    }
}

// MARK: - Game Countdown

struct GameCountdownView: View {
    @State private var count = 3
    @State private var scale: CGFloat = 0.5
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Text("\(count)")
                .font(.system(size: 180, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.cyan, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .scaleEffect(scale)
                .onAppear {
                    startCountdown()
                }
        }
    }
    
    private func startCountdown() {
        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                count = 3 - i
                scale = 0.5
                
                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()
                
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.2
                }
            }
        }
    }
}

// MARK: - Game Question View

struct GameQuestionView: View {
    let session: GameSession
    @State private var isAnimating = false
    
    var recognizedText: String {
        session.speechService.recognizedText
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Recording indicator
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("NAGRYWANIE")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Question text
                if let question = session.currentQuestion {
                    Text(question.text)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(8)
                }
                
                Spacer()
                
                // Recognized text feedback
                VStack(spacing: 12) {
                    Text("Powiedz: 'tak' lub 'nie'")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if !recognizedText.isEmpty {
                        Text("Słyszę: \(recognizedText)")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.cyan.opacity(0.2))
                            )
                    }
                }
                .padding(.bottom, 80)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    GameSessionView(
        session: GameSession(
            player: Player(name: "Jan", age: 25, gender: .male),
            questions: GameQuestionGenerator.getQuickGamePack()
        ),
        onComplete: {}
    )
}
