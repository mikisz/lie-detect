//
//  HotSeatSession.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftUI
import simd

/// Manages a Hot Seat multiplayer session
@Observable
class HotSeatSession {
    // MARK: - Services
    let faceTrackingService = FaceTrackingService()
    let speechService = SpeechRecognitionService()
    
    // MARK: - Session Configuration
    let players: [Player]
    let questions: [GameQuestion]
    let questionsPerPlayer: Int
    
    // MARK: - Session State
    var currentPlayerIndex = 0
    var currentQuestionIndex = 0
    var currentPhase: HotSeatPhase = .intro
    var allResults: [UUID: [QuestionResult]] = [:]  // playerID: results
    
    // MARK: - Computed Properties
    var currentPlayer: Player {
        players[currentPlayerIndex]
    }
    
    var currentQuestion: GameQuestion? {
        let playerQuestions = getQuestionsForCurrentPlayer()
        let localIndex = currentQuestionIndex % questionsPerPlayer
        guard localIndex < playerQuestions.count else { return nil }
        return playerQuestions[localIndex]
    }
    
    var currentPlayerProgress: Double {
        let localIndex = currentQuestionIndex % questionsPerPlayer
        return Double(localIndex) / Double(questionsPerPlayer)
    }
    
    var currentPlayerQuestionNumber: Int {
        (currentQuestionIndex % questionsPerPlayer) + 1
    }
    
    var isLastQuestion: Bool {
        let localIndex = currentQuestionIndex % questionsPerPlayer
        return localIndex >= questionsPerPlayer - 1
    }
    
    var isLastPlayer: Bool {
        currentPlayerIndex >= players.count - 1
    }
    
    var isSessionComplete: Bool {
        isLastPlayer && isLastQuestion
    }
    
    var overallWinner: Player? {
        // Player with most truthful answers wins
        var scores: [(Player, Int)] = []
        
        for player in players {
            let results = allResults[player.id] ?? []
            let truthfulCount = results.filter { !$0.verdict.isSuspicious }.count
            scores.append((player, truthfulCount))
        }
        
        return scores.max(by: { $0.1 < $1.1 })?.0
    }
    
    // MARK: - Initialization
    init(players: [Player], questions: [GameQuestion], questionsPerPlayer: Int = 5) {
        self.players = players
        self.questions = questions
        self.questionsPerPlayer = questionsPerPlayer
        
        // Initialize results dictionary
        for player in players {
            allResults[player.id] = []
        }
    }
    
    // MARK: - Flow Control
    
    func startSession() {
        currentPhase = .intro
        faceTrackingService.startTracking()
        print("🎮 Starting Hot Seat session with \(players.count) players")
    }
    
    func startPlayerTurn() {
        currentPhase = .playerIntro
        currentQuestionIndex = currentPlayerIndex * questionsPerPlayer
        print("👤 Starting turn for \(currentPlayer.name)")
    }
    
    func proceedToNextQuestion() {
        currentPhase = .prepare
    }
    
    func startQuestionRecording() {
        currentPhase = .countdown
        
        // After countdown, show question
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showQuestion()
        }
    }
    
    func showQuestion() {
        currentPhase = .question
        
        // Start recording
        faceTrackingService.startRecording()
        
        let questionStartTime = Date()
        
        // Start listening for answer
        speechService.startListening { [weak self] answer in
            guard let self = self else { return }
            
            let responseDuration = Date().timeIntervalSince(questionStartTime)
            let faceSamples = self.faceTrackingService.stopRecording()
            
            // Analyze response
            if let question = self.currentQuestion {
                let verdict = self.analyzeResponse(
                    player: self.currentPlayer,
                    question: question,
                    answer: answer,
                    faceSamples: faceSamples,
                    duration: responseDuration
                )
                
                let result = QuestionResult(
                    question: question,
                    spokenAnswer: answer,
                    faceSamples: faceSamples,
                    responseDuration: responseDuration,
                    verdict: verdict
                )
                
                // Store result for current player
                self.allResults[self.currentPlayer.id]?.append(result)
                
                print("✅ \(self.currentPlayer.name) answered - Verdict: \(verdict.isSuspicious ? "SUSPICIOUS" : "TRUTHFUL")")
            }
            
            // Show verdict
            self.currentPhase = .verdict
        }
    }
    
    func advanceToNextQuestion() {
        currentQuestionIndex += 1
        
        if isLastQuestion && !isLastPlayer {
            // Move to next player
            currentPhase = .playerComplete
        } else if isSessionComplete {
            // All done
            currentPhase = .sessionComplete
        } else {
            // Next question for same player
            proceedToNextQuestion()
        }
    }
    
    func moveToNextPlayer() {
        currentPlayerIndex += 1
        startPlayerTurn()
    }
    
    // MARK: - Question Management
    
    private func getQuestionsForCurrentPlayer() -> [GameQuestion] {
        let startIndex = currentPlayerIndex * questionsPerPlayer
        let endIndex = min(startIndex + questionsPerPlayer, questions.count)
        return Array(questions[startIndex..<endIndex])
    }
    
    // MARK: - Analysis
    
    private func analyzeResponse(
        player: Player,
        question: GameQuestion,
        answer: SpokenAnswer,
        faceSamples: [FaceSample],
        duration: TimeInterval
    ) -> QuestionVerdict {
        guard let calibration = player.calibrationData else {
            return QuestionVerdict(
                confidence: 0.5,
                isSuspicious: false,
                factors: ["Brak kalibracji".localized]
            )
        }
        
        // Get baseline
        let baseline = answer == .yes ? calibration.yesBaseline : calibration.noBaseline
        
        var suspicionScore: Float = 0.0
        var factors: [String] = []
        
        // 1. Blink rate
        let blinkCount = countBlinks(in: faceSamples)
        let sampleDuration = faceSamples.last?.timestamp ?? 1.0
        let blinkRate = Float(blinkCount) / Float(sampleDuration)
        
        let blinkDelta = abs(blinkRate - baseline.blinkRateMean)
        if blinkDelta > baseline.blinkRateStdDev * 2 {
            suspicionScore += 0.3
            factors.append(blinkRate > baseline.blinkRateMean ? "verdict.more_blinks".localized : "verdict.less_blinks".localized)
        }
        
        // 2. Response time
        let durationDelta = abs(Float(duration) - Float(baseline.responseDurationMean))
        if durationDelta > Float(baseline.responseDurationStdDev) * 2 {
            suspicionScore += 0.25
            factors.append(duration > baseline.responseDurationMean ? "verdict.longer_response".localized : "verdict.faster_response".localized)
        }
        
        // 3. Head movement
        let headMovement = calculateHeadMovement(in: faceSamples)
        if headMovement > 0.3 {
            suspicionScore += 0.2
            factors.append("verdict.head_movement".localized)
        }
        
        // 4. Facial tension
        let avgBrowMovement = faceSamples.map { $0.browInnerUp }.reduce(0, +) / Float(faceSamples.count)
        if avgBrowMovement > 0.5 {
            suspicionScore += 0.15
            factors.append("verdict.facial_tension".localized)
        }
        
        // 5. Extended pause
        if duration > baseline.responseDurationMean + baseline.responseDurationStdDev * 3 {
            suspicionScore += 0.1
            factors.append("verdict.long_pause".localized)
        }
        
        suspicionScore = min(suspicionScore, 1.0)
        let isSuspicious = suspicionScore > 0.5
        
        if factors.isEmpty {
            factors.append("verdict.normal_pattern".localized)
        }
        
        return QuestionVerdict(
            confidence: suspicionScore,
            isSuspicious: isSuspicious,
            factors: factors
        )
    }
    
    private func countBlinks(in samples: [FaceSample]) -> Int {
        var blinkCount = 0
        var wasBlinking = false
        
        for sample in samples {
            let avgBlink = (sample.eyeBlinkLeft + sample.eyeBlinkRight) / 2.0
            let isBlinking = avgBlink > 0.5
            
            if isBlinking && !wasBlinking {
                blinkCount += 1
            }
            wasBlinking = isBlinking
        }
        
        return blinkCount
    }
    
    private func calculateHeadMovement(in samples: [FaceSample]) -> Float {
        guard samples.count > 1 else { return 0 }
        
        var totalMovement: Float = 0
        
        for i in 1..<samples.count {
            let prev = samples[i-1].eulerAngles
            let curr = samples[i].eulerAngles
            
            let delta = simd_distance(prev, curr)
            totalMovement += delta
        }
        
        return totalMovement / Float(samples.count)
    }
    
    // MARK: - Results
    
    func getPlayerScore(_ player: Player) -> PlayerScore {
        let results = allResults[player.id] ?? []
        let truthfulCount = results.filter { !$0.verdict.isSuspicious }.count
        let suspiciousCount = results.filter { $0.verdict.isSuspicious }.count
        let totalQuestions = results.count
        
        let truthfulPercentage = totalQuestions > 0 ? Int((Float(truthfulCount) / Float(totalQuestions)) * 100) : 0
        
        return PlayerScore(
            player: player,
            truthfulCount: truthfulCount,
            suspiciousCount: suspiciousCount,
            totalQuestions: totalQuestions,
            truthfulPercentage: truthfulPercentage
        )
    }
    
    func getAllScores() -> [PlayerScore] {
        players.map { getPlayerScore($0) }
            .sorted { $0.truthfulPercentage > $1.truthfulPercentage }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        faceTrackingService.stopTracking()
        speechService.stopListening()
    }
}

// MARK: - Supporting Types

enum HotSeatPhase {
    case intro              // Session introduction
    case playerIntro        // Introduce current player
    case prepare            // Pre-question face check
    case countdown          // 3-2-1 countdown
    case question           // Question + recording
    case verdict            // Show verdict for current question
    case playerComplete     // Current player finished
    case sessionComplete    // All players finished
}

struct PlayerScore {
    let player: Player
    let truthfulCount: Int
    let suspiciousCount: Int
    let totalQuestions: Int
    let truthfulPercentage: Int
    
    var emoji: String {
        if truthfulPercentage >= 80 {
            return "😇"
        } else if truthfulPercentage >= 60 {
            return "😊"
        } else if truthfulPercentage >= 40 {
            return "😐"
        } else if truthfulPercentage >= 20 {
            return "😬"
        } else {
            return "🤥"
        }
    }
    
    var rank: String {
        if truthfulPercentage >= 80 {
            return "Mistrz Prawdy".localized
        } else if truthfulPercentage >= 60 {
            return "Uczciwy".localized
        } else if truthfulPercentage >= 40 {
            return "Średnio".localized
        } else {
            return "Podejrzany".localized
        }
    }
}
