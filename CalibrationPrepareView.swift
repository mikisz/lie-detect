//
//  CalibrationPrepareView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// Pre-question preparation view that checks face tracking quality
struct CalibrationPrepareView: View {
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
                // Progress
                VStack(spacing: 8) {
                    Text("calibration.question_of".localized(coordinator.currentQuestionIndex + 1, coordinator.questions.count))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                    
                    ProgressView(value: coordinator.progress)
                        .tint(.cyan)
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                }
                .padding(.top, 60)
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Face quality indicator
                VStack(spacing: 32) {
                    ZStack {
                        // Pulsing rings
                        ForEach(0..<2, id: \.self) { index in
                            Circle()
                                .stroke(
                                    qualityColor.opacity(0.4),
                                    lineWidth: 3
                                )
                                .frame(width: 150 + CGFloat(index) * 30, height: 150 + CGFloat(index) * 30)
                                .scaleEffect(isAnimating ? 1.2 : 0.8)
                                .opacity(isAnimating ? 0 : 0.8)
                                .animation(
                                    .easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: false)
                                    .delay(Double(index) * 0.3),
                                    value: isAnimating
                                )
                        }
                        
                        // Center icon
                        Image(systemName: qualityIcon)
                            .font(.system(size: 60, weight: .semibold))
                            .foregroundColor(qualityColor)
                    }
                    
                    VStack(spacing: 12) {
                        Text(qualityMessage)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        if coordinator.faceTrackingService.isFaceDetected {
                            Text("calibration.great_ready".localized)
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // Ready button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    coordinator.startQuestionRecording()
                }) {
                    Text("button.im_ready".localized)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    isReadyToStart ?
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue],
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
                            color: isReadyToStart ? Color.cyan.opacity(0.5) : Color.clear,
                            radius: 20,
                            y: 10
                        )
                }
                .disabled(!isReadyToStart)
                .padding(.horizontal, 32)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
    
    private var isReadyToStart: Bool {
        coordinator.faceTrackingService.isFaceDetected &&
        coordinator.faceTrackingService.faceQuality != .poor
    }
    
    private var qualityIcon: String {
        if !coordinator.faceTrackingService.isFaceDetected {
            return "person.fill.questionmark"
        }
        
        switch coordinator.faceTrackingService.faceQuality {
        case .unknown: return "questionmark.circle.fill"
        case .poor: return "exclamationmark.triangle.fill"
        case .fair: return "face.smiling"
        case .good: return "checkmark.circle.fill"
        }
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
    
    private var qualityMessage: String {
        if !coordinator.faceTrackingService.isFaceDetected {
            return "calibration.finding_face".localized
        }

        return coordinator.faceTrackingService.faceQuality.localizedMessage
    }
}

// MARK: - Countdown View

struct CalibrationCountdownView: View {
    @State private var count = 3
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if count > 0 {
                Text("\(count)")
                    .font(.system(size: 150, weight: .black))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(scale)
                    .opacity(opacity)
                    .shadow(color: Color.cyan.opacity(0.8), radius: 30, y: 10)
            }
        }
        .onAppear {
            animateCountdown()
        }
    }

    private func animateCountdown() {
        let audioService = AudioService.shared

        scale = 0.5
        opacity = 0

        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            scale = 1.2
            opacity = 1
        }

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

        // Shrink after a moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = 0.8
                opacity = 0
            }
        }

        // Move to next number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            if count > 1 {
                count -= 1
                animateCountdown()
            } else {
                // Play "Answer now!" after countdown finishes
                audioService.playVoice(.countdownGo)
            }
        }
    }
}

#Preview("Prepare") {
    CalibrationPrepareView(
        coordinator: CalibrationCoordinator(player: Player(name: "Jan", age: 25, gender: .male))
    )
}

#Preview("Countdown") {
    CalibrationCountdownView()
}
