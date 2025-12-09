//
//  VerdictRevealView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

enum Verdict {
    case truth
    case lie
    
    var text: String {
        switch self {
        case .truth: return "PRAWDA"
        case .lie: return "KŁAMSTWO"
        }
    }
    
    var emoji: String {
        switch self {
        case .truth: return "✅"
        case .lie: return "❌"
        }
    }
    
    var colors: [Color] {
        switch self {
        case .truth: return [Color.green, Color.teal]
        case .lie: return [Color.red, Color.orange]
        }
    }
}

struct VerdictRevealView: View {
    let verdict: Verdict
    @State private var phase: RevealPhase = .suspense
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -180
    
    enum RevealPhase {
        case suspense
        case reveal
    }
    
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
            
            if phase == .suspense {
                // Suspense animation
                VStack(spacing: 32) {
                    Text("🔍")
                        .font(.system(size: 100))
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    Text("Analizuję odpowiedź...")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(opacity)
                    
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                        .opacity(opacity)
                }
            } else {
                // Verdict reveal with dramatic animation
                VStack(spacing: 40) {
                    // Emoji
                    Text(verdict.emoji)
                        .font(.system(size: 120))
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                        .opacity(opacity)
                    
                    // Verdict text
                    Text(verdict.text)
                        .font(.system(size: 56, weight: .black))
                        .foregroundStyle(
                            LinearGradient(
                                colors: verdict.colors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .shadow(color: verdict.colors.first!.opacity(0.8), radius: 30, y: 10)
                    
                    // Decorative lines
                    HStack(spacing: 20) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: verdict.colors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: 60, height: 8)
                                .scaleEffect(x: scale, y: 1)
                                .opacity(opacity)
                                .animation(
                                    .spring(response: 0.6, dampingFraction: 0.6)
                                    .delay(Double(index) * 0.1 + 0.3),
                                    value: scale
                                )
                        }
                    }
                }
            }
        }
        .onAppear {
            // Suspense phase
            withAnimation(.easeIn(duration: 0.3)) {
                opacity = 1
            }
            
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.6)
            ) {
                scale = 1.0
            }
            
            // Transition to reveal after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeOut(duration: 0.2)) {
                    opacity = 0
                    scale = 0.8
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    phase = .reveal
                    scale = 0.5
                    opacity = 0
                    rotation = -180
                    
                    // Dramatic reveal animation
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        scale = 1.2
                        opacity = 1
                        rotation = 0
                    }
                    
                    // Haptic feedback
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(verdict == .truth ? .success : .error)
                    
                    // Settle animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            scale = 1.0
                        }
                    }
                }
            }
        }
    }
}

#Preview("Truth") {
    VerdictRevealView(verdict: .truth)
}

#Preview("Lie") {
    VerdictRevealView(verdict: .lie)
}
