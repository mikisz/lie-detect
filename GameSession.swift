//
//  GameSession.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftUI
import simd

/// Represents a single game session with questions and verdicts
@Observable
class GameSession {
    // MARK: - Services
    let faceTrackingService = FaceTrackingService()
    let speechService = SpeechRecognitionService()
    
    // MARK: - Session Configuration
    let player: Player
    let questions: [GameQuestion]
    let sessionType: SessionType
    
    // MARK: - Session State
    var currentQuestionIndex = 0
    var currentPhase: GamePhase = .intro
    var questionResults: [QuestionResult] = []
    
    // MARK: - Computed Properties
    var currentQuestion: GameQuestion? {
        guard currentQuestionIndex < questions.count else { return nil }
        return questions[currentQuestionIndex]
    }
    
    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }
    
    var isComplete: Bool {
        currentQuestionIndex >= questions.count
    }
    
    var overallVerdict: SessionVerdict {
        let lieCount = questionResults.filter { $0.verdict.isSuspicious }.count
        let totalQuestions = questionResults.count
        
        guard totalQuestions > 0 else { return .inconclusive }
        
        let suspiciousRatio = Double(lieCount) / Double(totalQuestions)
        
        if suspiciousRatio >= 0.5 {
            return .mostlyLying
        } else if suspiciousRatio >= 0.3 {
            return .mixed
        } else {
            return .mostlyTruthful
        }
    }
    
    // MARK: - Initialization
    init(player: Player, questions: [GameQuestion], sessionType: SessionType = .solo) {
        self.player = player
        self.questions = questions
        self.sessionType = sessionType
    }
    
    // MARK: - Flow Control
    
    func startSession() {
        currentPhase = .intro
        faceTrackingService.startTracking()
        print("🎮 Starting game session for \(player.name)")
    }
    
    func proceedToNextQuestion() {
        if currentQuestionIndex < questions.count {
            currentPhase = .prepare
        } else {
            currentPhase = .sessionComplete
        }
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
        
        // Start recording face data
        faceTrackingService.startRecording()
        
        let questionStartTime = Date()
        
        // Start listening for answer
        speechService.startListening { [weak self] answer in
            guard let self = self else { return }
            
            let responseDuration = Date().timeIntervalSince(questionStartTime)
            
            // Stop recording
            let faceSamples = self.faceTrackingService.stopRecording()
            
            // Analyze the response
            if let question = self.currentQuestion {
                let verdict = self.analyzeResponse(
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
                
                self.questionResults.append(result)
                
                print("✅ Recorded answer '\(answer.rawValue)' - Verdict: \(verdict.isSuspicious ? "SUSPICIOUS" : "TRUTHFUL")")
            }
            
            // Show verdict reveal
            self.currentPhase = .verdict
        }
    }
    
    func advanceToNextQuestion() {
        currentQuestionIndex += 1
        proceedToNextQuestion()
    }
    
    // MARK: - Analysis
    
    private func analyzeResponse(
        question: GameQuestion,
        answer: SpokenAnswer,
        faceSamples: [FaceSample],
        duration: TimeInterval
    ) -> QuestionVerdict {
        guard let calibration = player.calibrationData else {
            // No calibration - return neutral verdict
            return QuestionVerdict(
                confidence: 0.5,
                isSuspicious: false,
                factors: ["Brak kalibracji"]
            )
        }
        
        // Get the appropriate baseline
        let baseline = answer == .yes ? calibration.yesBaseline : calibration.noBaseline
        
        // Analyze factors
        var suspicionScore: Float = 0.0
        var factors: [String] = []
        
        // 1. Blink rate analysis
        let blinkCount = countBlinks(in: faceSamples)
        let sampleDuration = faceSamples.last?.timestamp ?? 1.0
        let blinkRate = Float(blinkCount) / Float(sampleDuration)
        
        let blinkDelta = abs(blinkRate - baseline.blinkRateMean)
        if blinkDelta > baseline.blinkRateStdDev * 2 {
            suspicionScore += 0.3
            factors.append(blinkRate > baseline.blinkRateMean ? "Częstsze mruganie" : "Rzadsze mruganie")
        }
        
        // 2. Response time analysis
        let durationDelta = abs(Float(duration) - Float(baseline.responseDurationMean))
        if durationDelta > Float(baseline.responseDurationStdDev) * 2 {
            suspicionScore += 0.25
            factors.append(duration > baseline.responseDurationMean ? "Dłuższy czas odpowiedzi" : "Zbyt szybka odpowiedź")
        }
        
        // 3. Head movement analysis
        let headMovement = calculateHeadMovement(in: faceSamples)
        if headMovement > 0.3 { // threshold
            suspicionScore += 0.2
            factors.append("Ruch głową")
        }
        
        // 4. Micro-expression check (brow movements)
        let avgBrowMovement = faceSamples.map { $0.browInnerUp }.reduce(0, +) / Float(faceSamples.count)
        if avgBrowMovement > 0.5 {
            suspicionScore += 0.15
            factors.append("Napięcie twarzy")
        }
        
        // 5. Extended pause before answer
        if duration > baseline.responseDurationMean + baseline.responseDurationStdDev * 3 {
            suspicionScore += 0.1
            factors.append("Długa pauza")
        }
        
        // Normalize score to 0-1 range
        suspicionScore = min(suspicionScore, 1.0)
        
        let isSuspicious = suspicionScore > 0.5
        
        if factors.isEmpty {
            factors.append("Normalny wzorzec")
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
    
    // MARK: - Cleanup
    
    func cleanup() {
        faceTrackingService.stopTracking()
        speechService.stopListening()
    }
}

// MARK: - Supporting Types

enum GamePhase {
    case intro              // Session introduction
    case prepare            // Pre-question face check
    case countdown          // 3-2-1 countdown
    case question           // Question + recording
    case verdict            // Show verdict for current question
    case sessionComplete    // All questions done, show summary
}

enum SessionType {
    case solo       // Single player
    case hotSeat    // Pass the device
    case online     // Future: online multiplayer
}

enum SessionVerdict {
    case mostlyTruthful
    case mixed
    case mostlyLying
    case inconclusive
    
    var emoji: String {
        switch self {
        case .mostlyTruthful: return "✅"
        case .mixed: return "🤔"
        case .mostlyLying: return "🤥"
        case .inconclusive: return "❓"
        }
    }
    
    var title: String {
        switch self {
        case .mostlyTruthful: return "Prawdomówny!"
        case .mixed: return "Mieszane sygnały"
        case .mostlyLying: return "Podejrzane..."
        case .inconclusive: return "Niejednoznaczne"
        }
    }
    
    var message: String {
        switch self {
        case .mostlyTruthful:
            return "Większość odpowiedzi wydaje się szczera"
        case .mixed:
            return "Niektóre odpowiedzi budzą wątpliwości"
        case .mostlyLying:
            return "Wykryto wiele podejrzanych sygnałów"
        case .inconclusive:
            return "Nie można określić z wystarczającą pewnością"
        }
    }
    
    var color: Color {
        switch self {
        case .mostlyTruthful: return .green
        case .mixed: return .orange
        case .mostlyLying: return .red
        case .inconclusive: return .gray
        }
    }
}

struct QuestionResult {
    let question: GameQuestion
    let spokenAnswer: SpokenAnswer
    let faceSamples: [FaceSample]
    let responseDuration: TimeInterval
    let verdict: QuestionVerdict
}

struct QuestionVerdict {
    let confidence: Float      // 0.0 to 1.0
    let isSuspicious: Bool
    let factors: [String]      // Contributing factors
    
    var percentage: Int {
        Int(confidence * 100)
    }
}

struct GameQuestion {
    let id: UUID
    let text: String
    let category: QuestionCategory
    
    init(text: String, category: QuestionCategory = .general) {
        self.id = UUID()
        self.text = text
        self.category = category
    }
}

enum QuestionCategory {
    case general
    case personal
    case spicy
    case relationships
    case secrets
    
    var emoji: String {
        switch self {
        case .general: return "💬"
        case .personal: return "👤"
        case .spicy: return "🌶️"
        case .relationships: return "❤️"
        case .secrets: return "🤫"
        }
    }
}
