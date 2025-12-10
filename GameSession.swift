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
    let verdictMode: VerdictMode
    
    // MARK: - Session State
    var currentQuestionIndex = 0
    var currentPhase: GamePhase = .intro
    var questionResults: [QuestionResult] = []

    // Timeout handling
    var showTimeoutAlert = false
    
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
    init(player: Player, questions: [GameQuestion], sessionType: SessionType = .solo, verdictMode: VerdictMode = .afterEach) {
        self.player = player
        self.questions = questions
        self.sessionType = sessionType
        self.verdictMode = verdictMode
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

        // After countdown, show question for reading (no recording yet)
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showReadQuestion()
        }
    }

    /// Show question for user to read (no recording)
    func showReadQuestion() {
        currentPhase = .readQuestion
        print("📖 Showing question for reading: \(currentQuestion?.text ?? "?")")
    }

    /// User is ready to answer - start recording
    func startAnswerRecording() {
        currentPhase = .answer

        // Start recording face data
        faceTrackingService.startRecording()

        let questionStartTime = Date()

        // Start listening for answer with timeout
        speechService.startListening(timeout: 10.0) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .answer(let answer):
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

                // Show verdict reveal or go to next question based on mode
                if self.verdictMode == .afterEach {
                    self.currentPhase = .verdict
                } else {
                    // atEnd mode - skip verdict, go to next question
                    self.advanceToNextQuestion()
                }

            case .timeout:
                // Stop recording face data
                _ = self.faceTrackingService.stopRecording()

                // Show timeout alert
                self.showTimeoutAlert = true

                // Haptic warning feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.warning)

                print("⏰ Speech recognition timed out")

            case .error(let message):
                // Stop recording face data
                _ = self.faceTrackingService.stopRecording()

                print("❌ Speech recognition error: \(message)")
                self.showTimeoutAlert = true
            }
        }
    }

    /// Retry current question after timeout
    func retryAfterTimeout() {
        showTimeoutAlert = false
        speechService.resetTimeout()
        currentPhase = .prepare
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
                factors: ["factor.no_calibration".localized]
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
            factors.append(blinkRate > baseline.blinkRateMean ? "factor.more_blinking".localized : "factor.less_blinking".localized)
        }

        // 2. Response time analysis
        let durationDelta = abs(Float(duration) - Float(baseline.responseDurationMean))
        if durationDelta > Float(baseline.responseDurationStdDev) * 2 {
            suspicionScore += 0.25
            factors.append(duration > baseline.responseDurationMean ? "factor.longer_response".localized : "factor.faster_response".localized)
        }

        // 3. Head movement analysis
        let headMovement = calculateHeadMovement(in: faceSamples)
        if headMovement > 0.3 { // threshold
            suspicionScore += 0.2
            factors.append("factor.head_movement".localized)
        }

        // 4. Micro-expression check (brow movements)
        let avgBrowMovement = faceSamples.isEmpty ? 0 : faceSamples.map { $0.browInnerUp }.reduce(0, +) / Float(faceSamples.count)
        if avgBrowMovement > 0.5 {
            suspicionScore += 0.15
            factors.append("factor.facial_tension".localized)
        }

        // 5. Extended pause before answer
        if duration > baseline.responseDurationMean + baseline.responseDurationStdDev * 3 {
            suspicionScore += 0.1
            factors.append("factor.long_pause".localized)
        }

        // Normalize score to 0-1 range
        suspicionScore = min(suspicionScore, 1.0)

        let isSuspicious = suspicionScore > 0.5

        if factors.isEmpty {
            factors.append("factor.normal_pattern".localized)
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
    case readQuestion       // Show question for reading (no recording)
    case answer             // Recording phase - question at top, camera preview
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
        case .mostlyTruthful: return "session.verdict.truthful.title".localized
        case .mixed: return "session.verdict.mixed.title".localized
        case .mostlyLying: return "session.verdict.lying.title".localized
        case .inconclusive: return "session.verdict.inconclusive.title".localized
        }
    }

    var message: String {
        switch self {
        case .mostlyTruthful:
            return "session.verdict.truthful.message".localized
        case .mixed:
            return "session.verdict.mixed.message".localized
        case .mostlyLying:
            return "session.verdict.lying.message".localized
        case .inconclusive:
            return "session.verdict.inconclusive.message".localized
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
