//
//  GameVerdictView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

/// Dramatic reveal of the verdict for a single question
struct GameVerdictView: View {
    let result: QuestionResult
    let session: GameSession
    
    @State private var showSuspense = true
    @State private var showVerdict = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background color based on verdict
            verdictGradient
                .ignoresSafeArea()
                .opacity(showVerdict ? 1 : 0)
            
            Color.black
                .ignoresSafeArea()
                .opacity(showSuspense ? 1 : 0)
            
            if showSuspense {
                // Suspense phase
                VStack(spacing: 30) {
                    Text("🔍")
                        .font(.system(size: 100))
                        .rotationEffect(.degrees(rotation))
                    
                    Text("Analizuję...")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            
            if showVerdict {
                // Verdict reveal
                VStack(spacing: 40) {
                    // Icon
                    Text(result.verdict.isSuspicious ? "🤥" : "✅")
                        .font(.system(size: 120))
                        .scaleEffect(scale)
                    
                    // Verdict text
                    VStack(spacing: 12) {
                        Text(result.verdict.isSuspicious ? "Podejrzane!" : "Prawda!")
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("Pewność: \(result.verdict.percentage)%")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    // Factors
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Wykryto:")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        ForEach(result.verdict.factors, id: \.self) { factor in
                            HStack(spacing: 8) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                Text(factor)
                                    .font(.system(size: 16))
                            }
                            .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                    )
                    .padding(.horizontal, 40)
                    
                    Spacer()
                    
                    // Continue button
                    Button(action: {
                        session.advanceToNextQuestion()
                    }) {
                        Text(session.isComplete ? "Zobacz wyniki" : "Następne pytanie")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.2))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 60)
                }
                .padding(.top, 80)
            }
        }
        .onAppear {
            playRevealAnimation()
        }
    }
    
    private var verdictGradient: some View {
        LinearGradient(
            colors: result.verdict.isSuspicious ?
                [Color.red.opacity(0.4), Color.orange.opacity(0.4)] :
                [Color.green.opacity(0.4), Color.cyan.opacity(0.4)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func playRevealAnimation() {
        // Suspense animation
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        // Trigger haptic
        let generator = UINotificationFeedbackGenerator()
        
        // After suspense, show verdict
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuspense = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showVerdict = true
                }
                
                // Dramatic scale animation
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    scale = 1.0
                }
                
                // Haptic feedback
                generator.notificationOccurred(result.verdict.isSuspicious ? .warning : .success)
            }
        }
    }
}

// MARK: - Game Complete View

struct GameCompleteView: View {
    let session: GameSession
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var showResults = false
    
    var body: some View {
        ZStack {
            // Background based on overall verdict
            overallGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Text(session.overallVerdict.emoji)
                            .font(.system(size: 100))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text("Sesja zakończona!")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                        
                        Text(session.overallVerdict.title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white.opacity(0.9))
                        
                        Text(session.overallVerdict.message)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 60)
                    
                    // Stats
                    VStack(spacing: 16) {
                        StatCard(
                            icon: "checkmark.circle.fill",
                            title: "Prawda",
                            value: "\(truthfulCount)",
                            color: .green
                        )
                        
                        StatCard(
                            icon: "exclamationmark.triangle.fill",
                            title: "Podejrzane",
                            value: "\(suspiciousCount)",
                            color: .orange
                        )
                        
                        StatCard(
                            icon: "chart.bar.fill",
                            title: "Łącznie pytań",
                            value: "\(session.questionResults.count)",
                            color: .cyan
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Show detailed results toggle
                    Button(action: {
                        withAnimation {
                            showResults.toggle()
                        }
                    }) {
                        HStack {
                            Text("Szczegóły odpowiedzi")
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: showResults ? "chevron.up" : "chevron.down")
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    if showResults {
                        VStack(spacing: 12) {
                            ForEach(Array(session.questionResults.enumerated()), id: \.offset) { index, result in
                                QuestionResultRow(index: index + 1, result: result)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: onDismiss) {
                            Text("Zakończ")
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
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            isAnimating = true
            
            // Haptic feedback
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
    
    private var overallGradient: some View {
        LinearGradient(
            colors: [
                session.overallVerdict.color.opacity(0.4),
                session.overallVerdict.color.opacity(0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var truthfulCount: Int {
        session.questionResults.filter { !$0.verdict.isSuspicious }.count
    }
    
    private var suspiciousCount: Int {
        session.questionResults.filter { $0.verdict.isSuspicious }.count
    }
}

struct StatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Spacer()
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(color.opacity(0.3), lineWidth: 2)
        )
    }
}

struct QuestionResultRow: View {
    let index: Int
    let result: QuestionResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Pytanie \(index)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                
                Spacer()
                
                Text(result.verdict.isSuspicious ? "🤥 Podejrzane" : "✅ Prawda")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(result.verdict.isSuspicious ? .orange : .green)
            }
            
            Text(result.question.text)
                .font(.system(size: 13))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(2)
            
            HStack(spacing: 8) {
                Text("Odpowiedź: \(result.spokenAnswer.displayText)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("•")
                    .foregroundColor(.white.opacity(0.3))
                
                Text("Pewność: \(result.verdict.percentage)%")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview("Truthful Verdict") {
    GameVerdictView(
        result: QuestionResult(
            question: GameQuestion(text: "Czy lubisz pizzę?"),
            spokenAnswer: .yes,
            faceSamples: [],
            responseDuration: 1.5,
            verdict: QuestionVerdict(confidence: 0.2, isSuspicious: false, factors: ["Normalny wzorzec"])
        ),
        session: GameSession(
            player: Player(name: "Jan", age: 25, gender: .male),
            questions: []
        )
    )
}

#Preview("Suspicious Verdict") {
    GameVerdictView(
        result: QuestionResult(
            question: GameQuestion(text: "Czy kiedykolwiek skłamałeś?"),
            spokenAnswer: .no,
            faceSamples: [],
            responseDuration: 3.2,
            verdict: QuestionVerdict(
                confidence: 0.75,
                isSuspicious: true,
                factors: ["Częstsze mruganie", "Dłuższy czas odpowiedzi", "Ruch głową"]
            )
        ),
        session: GameSession(
            player: Player(name: "Jan", age: 25, gender: .male),
            questions: []
        )
    )
}
