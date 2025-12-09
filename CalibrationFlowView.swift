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

                case .faceSetup:
                    FaceSetupView(coordinator: coordinator)
                        .transition(.opacity)

                case .prepare:
                    CalibrationPrepareView(coordinator: coordinator)
                        .transition(.opacity)

                case .countdown:
                    CalibrationCountdownView()
                        .transition(.opacity)

                case .readQuestion:
                    ReadQuestionView(coordinator: coordinator)
                        .transition(.opacity)

                case .answer:
                    AnswerView(coordinator: coordinator)
                        .transition(.opacity)

                case .wrongAnswer:
                    WrongAnswerView(coordinator: coordinator)
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
        .alert("speech.timeout.title".localized, isPresented: Bindable(coordinator).showTimeoutAlert) {
            Button("button.retry".localized) {
                coordinator.retryAfterTimeout()
            }
        } message: {
            Text("speech.timeout.message".localized)
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
                    coordinator.proceedToFaceSetup()
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

// MARK: - Face Setup View

struct FaceSetupView: View {
    let coordinator: CalibrationCoordinator

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // AR Camera Preview (actual camera feed)
            ARCameraPreview(faceTrackingService: coordinator.faceTrackingService)
                .ignoresSafeArea()

            // Dark overlay for better contrast
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top instruction
                VStack(spacing: 8) {
                    Text("Ustaw twarz")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4)

                    Text("Umieść twarz w ramce poniżej")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(color: .black.opacity(0.5), radius: 4)
                }
                .padding(.top, 60)

                Spacer()

                // Face frame guide
                ZStack {
                    // Outer glow
                    Ellipse()
                        .stroke(qualityColor.opacity(0.4), lineWidth: 8)
                        .frame(width: 260, height: 340)
                        .blur(radius: 10)

                    // Main face outline
                    Ellipse()
                        .stroke(qualityColor, lineWidth: 4)
                        .frame(width: 240, height: 320)

                    // Corner markers
                    FaceFrameCorners(color: qualityColor)
                        .frame(width: 260, height: 340)

                    // Scanning animation
                    if isAnimating && !coordinator.faceTrackingService.isFaceDetected {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        qualityColor.opacity(0),
                                        qualityColor.opacity(0.3),
                                        qualityColor.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: 220, height: 40)
                            .offset(y: isAnimating ? 140 : -140)
                            .animation(
                                .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                            .clipShape(Ellipse().size(width: 240, height: 320).offset(x: -10, y: -10))
                    }
                }
                .padding(.vertical, 20)

                Spacer()

                // Status indicators
                VStack(spacing: 16) {
                    // Face detection status
                    StatusRow(
                        icon: coordinator.faceTrackingService.isFaceDetected ? "checkmark.circle.fill" : "xmark.circle.fill",
                        text: coordinator.faceTrackingService.isFaceDetected ? "Twarz wykryta" : "Szukam twarzy...",
                        color: coordinator.faceTrackingService.isFaceDetected ? .green : .orange
                    )

                    // Quality status
                    StatusRow(
                        icon: qualityIcon,
                        text: qualityMessage,
                        color: qualityColor
                    )

                    // Lighting hint
                    if coordinator.faceTrackingService.faceQuality == .poor {
                        StatusRow(
                            icon: "lightbulb.fill",
                            text: "Upewnij się, że twarz jest dobrze oświetlona",
                            color: .yellow
                        )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 24)

                // Continue button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    coordinator.proceedToNextQuestion()
                }) {
                    HStack(spacing: 12) {
                        Text("Kontynuuj")
                            .font(.system(size: 20, weight: .bold))

                        if isReadyToContinue {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                isReadyToContinue ?
                                LinearGradient(
                                    colors: [Color.green, Color.teal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(
                        color: isReadyToContinue ? Color.green.opacity(0.5) : Color.clear,
                        radius: 20,
                        y: 10
                    )
                }
                .disabled(!isReadyToContinue)
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isAnimating = true
            }
        }
    }

    private var isReadyToContinue: Bool {
        coordinator.faceTrackingService.isFaceDetected &&
        coordinator.faceTrackingService.faceQuality == .good
    }

    private var qualityColor: Color {
        if !coordinator.faceTrackingService.isFaceDetected {
            return .gray
        }
        switch coordinator.faceTrackingService.faceQuality {
        case .unknown: return .gray
        case .poor: return .red
        case .fair: return .orange
        case .good: return .green
        }
    }

    private var qualityIcon: String {
        switch coordinator.faceTrackingService.faceQuality {
        case .unknown: return "questionmark.circle"
        case .poor: return "exclamationmark.triangle.fill"
        case .fair: return "arrow.up.and.down.and.arrow.left.and.right"
        case .good: return "checkmark.seal.fill"
        }
    }

    private var qualityMessage: String {
        if !coordinator.faceTrackingService.isFaceDetected {
            return "Ustaw twarz w ramce"
        }
        switch coordinator.faceTrackingService.faceQuality {
        case .unknown: return "Analizuję..."
        case .poor: return "Spójrz prosto w kamerę"
        case .fair: return "Prawie dobrze - wyśrodkuj twarz"
        case .good: return "Idealnie! Możesz kontynuować"
        }
    }
}

struct FaceFrameCorners: View {
    let color: Color
    let cornerLength: CGFloat = 30
    let lineWidth: CGFloat = 4

    var body: some View {
        GeometryReader { geo in
            // Top left
            Path { path in
                path.move(to: CGPoint(x: 0, y: cornerLength))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: cornerLength, y: 0))
            }
            .stroke(color, lineWidth: lineWidth)

            // Top right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - cornerLength, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: 0))
                path.addLine(to: CGPoint(x: geo.size.width, y: cornerLength))
            }
            .stroke(color, lineWidth: lineWidth)

            // Bottom left
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height - cornerLength))
                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                path.addLine(to: CGPoint(x: cornerLength, y: geo.size.height))
            }
            .stroke(color, lineWidth: lineWidth)

            // Bottom right
            Path { path in
                path.move(to: CGPoint(x: geo.size.width - cornerLength, y: geo.size.height))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height - cornerLength))
            }
            .stroke(color, lineWidth: lineWidth)
        }
    }
}

struct StatusRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(color.opacity(0.2))
                )
        )
    }
}

// MARK: - Wrong Answer View

struct WrongAnswerView: View {
    let coordinator: CalibrationCoordinator

    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Red-tinted background
            LinearGradient(
                colors: [
                    Color(red: 0.2, green: 0.05, blue: 0.05),
                    Color(red: 0.3, green: 0.1, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Error icon
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 8)
                        .frame(width: 140, height: 140)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeOut(duration: 1.5).repeatForever(autoreverses: false),
                            value: isAnimating
                        )

                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.red)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                }

                VStack(spacing: 16) {
                    Text("Nieprawidłowa odpowiedź!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(coordinator.wrongAnswerMessage)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                // Warning box
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)

                    Text("Kalibracja wymaga szczerych odpowiedzi, aby działać poprawnie")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.yellow.opacity(0.15))
                )
                .padding(.horizontal, 32)

                Spacer()

                // Retry button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    coordinator.retryCurrentQuestion()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 18, weight: .bold))

                        Text("Spróbuj ponownie")
                            .font(.system(size: 20, weight: .bold))
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
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    CalibrationFlowView(
        player: Player(name: "Jan", age: 25, gender: .male)
    )
    .modelContainer(for: [Player.self], inMemory: true)
}
