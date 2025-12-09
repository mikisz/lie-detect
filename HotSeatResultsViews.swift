//
//  HotSeatResultsViews.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import SwiftUI

// MARK: - Verdict View

struct HotSeatVerdictView: View {
    let session: HotSeatSession
    let result: QuestionResult
    
    @State private var showSuspense = true
    @State private var showVerdict = false
    @State private var scale: CGFloat = 0.5
    @State private var rotation: Double = 0
    @Environment(\.audioService) private var audioService
    
    var body: some View {
        ZStack {
            // Background
            verdictGradient
                .ignoresSafeArea()
                .opacity(showVerdict ? 1 : 0)
            
            Color.black
                .ignoresSafeArea()
                .opacity(showSuspense ? 1 : 0)
            
            if showSuspense {
                // Suspense
                VStack(spacing: 30) {
                    Text("🔍")
                        .font(.system(size: 100))
                        .rotationEffect(.degrees(rotation))
                    
                    Text("game.analyzing".localized)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                }
            }
            
            if showVerdict {
                // Verdict
                VStack(spacing: 40) {
                    Text(result.verdict.isSuspicious ? "🤥" : "✅")
                        .font(.system(size: 120))
                        .scaleEffect(scale)
                    
                    VStack(spacing: 12) {
                        Text(result.verdict.isSuspicious ? "verdict.suspicious".localized : "verdict.truthful".localized)
                            .font(.system(size: 48, weight: .black))
                            .foregroundColor(.white)
                        
                        Text("verdict.confidence".localized(result.verdict.percentage))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("verdict.factors".localized)
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
                    
                    Button(action: {
                        session.advanceToNextQuestion()
                    }) {
                        Text(session.isLastQuestion ? "button.next".localized : "game.next_question".localized)
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
        audioService.playSound(.suspense)
        
        withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        let generator = UINotificationFeedbackGenerator()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showSuspense = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.easeIn(duration: 0.3)) {
                    showVerdict = true
                }
                
                withAnimation(.spring(response: 0.6, dampingFraction: 0.5)) {
                    scale = 1.0
                }
                
                audioService.playSound(result.verdict.isSuspicious ? .suspicious : .truthful)
                generator.notificationOccurred(result.verdict.isSuspicious ? .warning : .success)
            }
        }
    }
}

// MARK: - Player Complete View

struct HotSeatPlayerCompleteView: View {
    let session: HotSeatSession
    @State private var isAnimating = false
    @Environment(\.audioService) private var audioService
    
    var playerScore: PlayerScore {
        session.getPlayerScore(session.currentPlayer)
    }
    
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
                
                Text(playerScore.emoji)
                    .font(.system(size: 100))
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                
                VStack(spacing: 16) {
                    Text("hotseat.player_complete".localized)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text(session.currentPlayer.name)
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.white)
                    
                    Text(playerScore.rank)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 16) {
                    ScoreCard(
                        icon: "checkmark.circle.fill",
                        title: "session.stats.truthful".localized,
                        value: "\(playerScore.truthfulCount)",
                        color: .green
                    )
                    
                    ScoreCard(
                        icon: "exclamationmark.triangle.fill",
                        title: "session.stats.suspicious".localized,
                        value: "\(playerScore.suspiciousCount)",
                        color: .orange
                    )
                    
                    ScoreCard(
                        icon: "chart.bar.fill",
                        title: "hotseat.accuracy".localized,
                        value: "\(playerScore.truthfulPercentage)%",
                        color: .cyan
                    )
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    audioService.playSound(.success)
                    session.moveToNextPlayer()
                }) {
                    Text("hotseat.next_player".localized)
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

// MARK: - Session Complete View

struct HotSeatCompleteView: View {
    let session: HotSeatSession
    let onDismiss: () -> Void
    
    @State private var isAnimating = false
    @State private var showDetails = false
    @Environment(\.audioService) private var audioService
    
    var scores: [PlayerScore] {
        session.getAllScores()
    }
    
    var winner: Player? {
        session.overallWinner
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange.opacity(0.5), Color.red.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        Text("🏆")
                            .font(.system(size: 100))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        
                        Text("hotseat.game_complete".localized)
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                        
                        if let winner = winner {
                            VStack(spacing: 8) {
                                Text("hotseat.winner".localized)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text(winner.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    .padding(.top, 60)
                    
                    // Leaderboard
                    VStack(spacing: 16) {
                        Text("hotseat.leaderboard".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        ForEach(Array(scores.enumerated()), id: \.element.player.id) { index, score in
                            LeaderboardRow(
                                rank: index + 1,
                                score: score,
                                isWinner: score.player.id == winner?.id
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Show details toggle
                    Button(action: {
                        withAnimation {
                            showDetails.toggle()
                        }
                    }) {
                        HStack {
                            Text("session.details".localized)
                                .font(.system(size: 16, weight: .semibold))
                            Spacer()
                            Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        }
                        .foregroundColor(.white)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    if showDetails {
                        ForEach(session.players) { player in
                            PlayerDetailCard(
                                player: player,
                                results: session.allResults[player.id] ?? []
                            )
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Finish button
                    Button(action: {
                        audioService.playSound(.success)
                        onDismiss()
                    }) {
                        Text("button.finish".localized)
                            .font(.system(size: 20, weight: .bold))
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
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            isAnimating = true
            
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

// MARK: - Supporting Views

struct ScoreCard: View {
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

struct LeaderboardRow: View {
    let rank: Int
    let score: PlayerScore
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            ZStack {
                Circle()
                    .fill(isWinner ? LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [.gray, .gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                    .frame(width: 40, height: 40)
                
                Text("\(rank)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Player avatar
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 50, height: 50)
                
                Text(score.player.initials)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(score.player.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                
                Text(score.rank)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Score
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(score.truthfulPercentage)%")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                
                Text("\(score.truthfulCount)/\(score.totalQuestions)")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(isWinner ? 0.2 : 0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isWinner ? Color.yellow.opacity(0.5) : Color.white.opacity(0.15), lineWidth: isWinner ? 2 : 1)
        )
    }
}

struct PlayerDetailCard: View {
    let player: Player
    let results: [QuestionResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(player.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
            
            ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                HStack {
                    Text("Q\(index + 1)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                        .frame(width: 30)
                    
                    Text(result.verdict.isSuspicious ? "🤥" : "✅")
                        .font(.system(size: 16))
                    
                    Text(result.question.text)
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("\(result.verdict.percentage)%")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(result.verdict.isSuspicious ? .orange : .green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
        )
    }
}

#Preview("Verdict") {
    HotSeatVerdictView(
        session: HotSeatSession(
            players: [Player(name: "Alice", age: 25, gender: .female)],
            questions: GameQuestionGenerator.getQuickGamePack()
        ),
        result: QuestionResult(
            question: GameQuestion(text: "Test question?"),
            spokenAnswer: .yes,
            faceSamples: [],
            responseDuration: 1.5,
            verdict: QuestionVerdict(confidence: 0.75, isSuspicious: true, factors: ["Test factor"])
        )
    )
}
