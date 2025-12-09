//
//  HotSeatGameView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// Main view coordinating Hot Seat game phases
struct HotSeatGameView: View {
    let session: HotSeatSession
    let onComplete: () -> Void

    @Environment(\.audioService) private var audioService

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                switch session.currentPhase {
                case .intro:
                    HotSeatIntroView(session: session)
                        .transition(.opacity)

                case .playerIntro:
                    HotSeatPlayerIntroView(session: session)
                        .transition(.opacity)

                case .prepare:
                    HotSeatPrepareView(session: session)
                        .transition(.opacity)

                case .countdown:
                    HotSeatCountdownView()
                        .transition(.opacity)

                case .readQuestion:
                    HotSeatReadQuestionView(session: session)
                        .transition(.opacity)

                case .answer:
                    HotSeatAnswerView(session: session)
                        .transition(.opacity)

                case .verdict:
                    if let results = session.allResults[session.currentPlayer.id],
                       let lastResult = results.last {
                        HotSeatVerdictView(session: session, result: lastResult)
                            .transition(.opacity)
                    }

                case .playerComplete:
                    HotSeatPlayerCompleteView(session: session)
                        .transition(.opacity)

                case .sessionComplete:
                    HotSeatCompleteView(session: session, onDismiss: onComplete)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: session.currentPhase)
        }
        .onAppear {
            audioService.playGameMusic()
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

// MARK: - Intro View

struct HotSeatIntroView: View {
    let session: HotSeatSession
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.red.opacity(0.3), Color.orange.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                Text("🔥")
                    .font(.system(size: 100))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 16) {
                    Text("hotseat.title".localized)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("hotseat.player_count".localized(session.players.count))
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("hotseat.questions_each".localized(session.questionsPerPlayer))
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
                
                // Player list
                VStack(alignment: .leading, spacing: 12) {
                    Text("hotseat.players_list".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    ForEach(Array(session.players.enumerated()), id: \.element.id) { index, player in
                        HStack(spacing: 12) {
                            Text("\(index + 1).")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.orange)
                                .frame(width: 30)
                            
                            ZStack {
                                Circle()
                                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .frame(width: 40, height: 40)
                                
                                Text(player.initials)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            
                            Text(player.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 40)
                
                VStack(spacing: 12) {
                    Text("💡 \("hotseat.remember".localized)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionRow(icon: "arrow.triangle.2.circlepath", text: "hotseat.pass_device".localized, color: .orange)
                        InstructionRow(icon: "eye.fill", text: "calibration.instruction.camera".localized, color: .orange)
                        InstructionRow(icon: "mic.fill", text: "calibration.instruction.voice".localized, color: .orange)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Button(action: {
                    session.startPlayerTurn()
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
                                        colors: [Color.orange, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.orange.opacity(0.5), radius: 20, y: 10)
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

// MARK: - Player Intro View

struct HotSeatPlayerIntroView: View {
    let session: HotSeatSession
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.4), Color.red.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Player avatar
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 150, height: 150)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text(session.currentPlayer.initials)
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 16) {
                    Text("hotseat.your_turn".localized)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(session.currentPlayer.name)
                        .font(.system(size: 48, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("hotseat.questions_for_you".localized(session.questionsPerPlayer))
                        .font(.system(size: 20))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 12) {
                    Text("⚡ \("hotseat.get_ready".localized)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("hotseat.pass_device_to".localized(session.currentPlayer.name))
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                Button(action: {
                    session.proceedToNextQuestion()
                }) {
                    Text("button.im_ready".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
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
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Prepare View

struct HotSeatPrepareView: View {
    let session: HotSeatSession
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
                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Progress and player info
                VStack(spacing: 12) {
                    Text(session.currentPlayer.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("game.question_of".localized(session.currentPlayerQuestionNumber, session.questionsPerPlayer))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    
                    ProgressView(value: session.currentPlayerProgress)
                        .tint(.orange)
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Face quality
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
                                    LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.gray, Color.gray.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                        )
                        .shadow(color: canProceed ? Color.orange.opacity(0.5) : .clear, radius: 20, y: 10)
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

// MARK: - Countdown View

struct HotSeatCountdownView: View {
    @State private var count = 3
    @State private var scale: CGFloat = 0.5
    @Environment(\.audioService) private var audioService

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Text("\(count)")
                .font(.system(size: 180, weight: .black))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange, Color.red],
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

                audioService.playSound(.countdown)

                // Play countdown voice
                switch count {
                case 3: audioService.playVoice(.countdown3)
                case 2: audioService.playVoice(.countdown2)
                case 1: audioService.playVoice(.countdown1)
                default: break
                }

                let generator = UIImpactFeedbackGenerator(style: .heavy)
                generator.impactOccurred()

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

// MARK: - Read Question View (Phase 1: Read, no recording)

struct HotSeatReadQuestionView: View {
    let session: HotSeatSession
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.3), Color.red.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                // Progress
                VStack(spacing: 8) {
                    Text(session.currentPlayer.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("game.question_of".localized(session.currentPlayerQuestionNumber, session.questionsPerPlayer))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    ProgressView(value: session.currentPlayerProgress)
                        .tint(.orange)
                        .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        .padding(.horizontal, 60)
                }
                .padding(.top, 60)

                Spacer()

                // Instruction
                Text("Przeczytaj pytanie")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.orange)
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

                    Text("Kiedy będziesz gotowy, spójrz w kamerę i odpowiedz")
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
                        Text("Jestem gotowy")
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
                                    colors: [Color.orange, Color.red],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.orange.opacity(0.5), radius: 20, y: 10)
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

// MARK: - Answer View (Phase 2: Camera + recording)

struct HotSeatAnswerView: View {
    let session: HotSeatSession
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
                    Text("\(session.currentPlayer.name) - \(session.currentPlayerQuestionNumber)/\(session.questionsPerPlayer)")
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
                    .stroke(Color.orange.opacity(0.4), lineWidth: 2)
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

                        Text("Słucham...")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 4)
                    }

                    Text("Powiedz 'tak' lub 'nie'")
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
    HotSeatGameView(
        session: HotSeatSession(
            players: [
                Player(name: "Alice", age: 25, gender: .female),
                Player(name: "Bob", age: 30, gender: .male)
            ],
            questions: GameQuestionGenerator.getQuickGamePack()
        ),
        onComplete: {}
    )
}
