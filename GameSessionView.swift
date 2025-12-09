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

                case .readQuestion:
                    GameReadQuestionView(session: session)
                        .transition(.opacity)

                case .answer:
                    GameAnswerView(session: session)
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
        .alert("speech.timeout.title".localized, isPresented: Bindable(session).showTimeoutAlert) {
            Button("button.retry".localized) {
                session.retryAfterTimeout()
            }
        } message: {
            Text("speech.timeout.message".localized)
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
                    Text("game.starting".localized)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)

                    Text("game.player".localized(session.player.name))
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))

                    Text("game.questions_count".localized(session.questions.count))
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("💡 \("game.remember".localized)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    InstructionRow(icon: "checkmark.circle.fill", text: "game.instruction.answer".localized, color: .green)
                    InstructionRow(icon: "eye.fill", text: "game.instruction.camera".localized, color: .cyan)
                    InstructionRow(icon: "mic.fill", text: "game.instruction.voice".localized, color: .cyan)
                }
                .padding(.horizontal, 40)

                Spacer()

                Button(action: {
                    session.proceedToNextQuestion()
                }) {
                    Text("general.start".localized)
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
                    Text("game.question_of".localized(session.currentQuestionIndex + 1, session.questions.count))
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

                    Text(faceQuality.localizedMessage)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }

                Spacer()

                // Ready button
                Button(action: {
                    session.startQuestionRecording()
                }) {
                    Text("button.im_ready".localized)
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
        let audioService = AudioService.shared

        for i in 0..<3 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i)) {
                count = 3 - i
                scale = 0.5

                // Haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()

                // Play countdown voice
                switch count {
                case 3: audioService.playVoice(.countdown3)
                case 2: audioService.playVoice(.countdown2)
                case 1: audioService.playVoice(.countdown1)
                default: break
                }

                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    scale = 1.2
                }
            }
        }

        // Play "Answer now!" after countdown
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            audioService.playVoice(.countdownGo)
        }
    }
}

// MARK: - Game Read Question View (Phase 1: Read, no recording)

struct GameReadQuestionView: View {
    let session: GameSession
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.2), Color.cyan.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Progress
                VStack(spacing: 8) {
                    Text("game.question_of".localized(session.currentQuestionIndex + 1, session.questions.count))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    ProgressView(value: session.progress)
                        .tint(.cyan)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        .padding(.horizontal, 60)
                }
                .padding(.top, 60)

                Spacer()

                // Instruction
                Text("game.read_question".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.cyan)
                    .opacity(isAnimating ? 1 : 0)

                // Question text - large for reading
                if let question = session.currentQuestion {
                    Text(question.text)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .lineSpacing(8)
                        .scaleEffect(isAnimating ? 1.0 : 0.9)
                        .opacity(isAnimating ? 1.0 : 0)
                }

                Spacer()

                // Instruction for next step
                VStack(spacing: 12) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))

                    Text("game.ready_hint".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Ready button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    session.startAnswerRecording()
                }) {
                    HStack(spacing: 12) {
                        Text("button.im_ready".localized)
                            .font(.system(size: 20, weight: .bold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold))
                    }
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
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Game Answer View (Phase 2: Camera + recording)

struct GameAnswerView: View {
    let session: GameSession
    @State private var isAnimating = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // AR Camera Preview
            ARCameraPreview(faceTrackingService: session.faceTrackingService)
                .ignoresSafeArea()

            // Dark overlay
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Question at TOP - near camera
                VStack(spacing: 8) {
                    Text("\(session.currentQuestionIndex + 1)/\(session.questions.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    if let question = session.currentQuestion {
                        Text(question.text)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.4),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .top)
                )

                Spacer()

                // Face guide
                Ellipse()
                    .stroke(Color.cyan.opacity(0.4), lineWidth: 2)
                    .frame(width: 200, height: 260)

                Spacer()

                // Recording indicator at bottom
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                            .scaleEffect(pulseScale)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: pulseScale
                            )

                        Text("speech.listening".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }

                    Text("speech.say_answer".localized)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.3)) {
                isAnimating = true
            }
            pulseScale = 1.2
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
