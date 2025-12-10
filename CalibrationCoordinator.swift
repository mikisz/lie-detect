//
//  CalibrationCoordinator.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftUI
import Combine

/// Coordinates the entire calibration flow for a player
@Observable
class CalibrationCoordinator {
    // MARK: - Services
    let faceTrackingService = FaceTrackingService()
    let speechService = SpeechRecognitionService()

    // MARK: - State
    var player: Player
    var questions: [CalibrationQuestion] = []
    var currentQuestionIndex = 0
    var currentPhase: CalibrationPhase = .intro

    // Collected data per question
    var questionResponses: [QuestionResponse] = []

    // Wrong answer handling
    var lastAnswerWasWrong = false
    var wrongAnswerMessage = ""

    // Timeout handling
    var showTimeoutAlert = false

    // Cleanup state
    private var isCleanedUp = false
    
    // MARK: - Computed Properties
    var currentQuestion: CalibrationQuestion? {
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
    
    // MARK: - Initialization
    init(player: Player) {
        self.player = player
        self.questions = CalibrationQuestionGenerator.generateQuestions(for: player)
    }
    
    // MARK: - Flow Control
    
    func startCalibration() {
        currentPhase = .intro
        print("📋 Starting calibration for \(player.name)")
    }

    func proceedToFaceSetup() {
        currentPhase = .faceSetup
    }

    func proceedToNextQuestion() {
        // Reset wrong answer state
        lastAnswerWasWrong = false
        wrongAnswerMessage = ""

        if currentQuestionIndex < questions.count {
            currentPhase = .prepare
        } else {
            currentPhase = .complete
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

        // Start face tracking recording
        faceTrackingService.startRecording()

        let questionStartTime = Date()

        // Start listening for answer with timeout
        speechService.startListening(timeout: 10.0) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .answer(let answer):
                let responseDuration = Date().timeIntervalSince(questionStartTime)

                // Stop recording face data
                let faceSamples = self.faceTrackingService.stopRecording()

                // Store response
                if let question = self.currentQuestion {
                    // VERIFY: Check if answer matches expected answer
                    if answer != question.expectedAnswer {
                        // User lied during calibration - this invalidates the data
                        self.lastAnswerWasWrong = true
                        let expectedText = question.expectedAnswer == .yes ? "general.yes".localized : "general.no".localized
                        self.wrongAnswerMessage = "calibration.honest_required".localized + "\n\n" + "calibration.answer_truthfully".localized(with: expectedText)

                        // Haptic error feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.error)

                        // Show wrong answer phase, then retry this question
                        self.currentPhase = .wrongAnswer
                        print("❌ Wrong answer! Expected '\(question.expectedAnswer.rawValue)', got '\(answer.rawValue)'")
                        return
                    }

                    let response = QuestionResponse(
                        question: question,
                        spokenAnswer: answer,
                        faceSamples: faceSamples,
                        responseDuration: responseDuration
                    )
                    self.questionResponses.append(response)

                    print("✅ Recorded answer '\(answer.rawValue)' for question \(self.currentQuestionIndex + 1)")

                    // Haptic success feedback
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()

                    // Move to next question
                    self.currentQuestionIndex += 1
                    self.proceedToNextQuestion()
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

                // Show timeout alert with error message
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

    func retryCurrentQuestion() {
        // Reset wrong answer state and go back to prepare
        lastAnswerWasWrong = false
        wrongAnswerMessage = ""
        currentPhase = .prepare
    }
    
    func finishCalibration() -> CalibrationData? {
        print("🎉 Calibration complete! Processing data...")

        // Separate responses by answer type
        let yesResponses = questionResponses.filter { $0.spokenAnswer == .yes }
        let noResponses = questionResponses.filter { $0.spokenAnswer == .no }

        // Compute baselines with real facial data analysis
        let yesBaseline = computeBaseline(from: yesResponses)
        let noBaseline = computeBaseline(from: noResponses)

        // Compute average face confidence from actual sample data
        // We expect ~30 samples per second during recording
        // Confidence = actual samples / expected samples
        let allSamples = questionResponses.flatMap { $0.faceSamples }
        let totalRecordingDuration = questionResponses.reduce(0.0) { $0 + $1.responseDuration }
        let expectedSamples = totalRecordingDuration * 30 // ~30 FPS for ARKit
        let avgConfidence: Float = allSamples.isEmpty || expectedSamples <= 0 ? 0.85 :
            min(1.0, Float(allSamples.count) / Float(expectedSamples))

        let calibrationData = CalibrationData(
            playerID: player.id,
            calibratedAt: Date(),
            yesBaseline: yesBaseline,
            noBaseline: noBaseline,
            sampleCount: questionResponses.count,
            averageFaceConfidence: avgConfidence
        )

        return calibrationData
    }
    
    // MARK: - Baseline Computation

    private func computeBaseline(from responses: [QuestionResponse]) -> FacialBaseline {
        // Collect all samples from responses
        let allSamples = responses.flatMap { $0.faceSamples }

        // Compute blink rates per response
        var blinkRates: [Float] = []
        var responseDurations: [TimeInterval] = []
        var gazeStabilities: [Float] = []

        for response in responses {
            // Count blinks in samples
            let blinkCount = countBlinks(in: response.faceSamples)
            let duration = response.faceSamples.last?.timestamp ?? 1.0
            // Avoid division by zero
            let blinkRate = duration > 0 ? Float(blinkCount) / Float(duration) : 0
            blinkRates.append(blinkRate)

            responseDurations.append(response.responseDuration)

            // Compute gaze stability for this response
            let stability = computeGazeStability(samples: response.faceSamples)
            gazeStabilities.append(stability)
        }

        // Compute blink rate statistics
        let meanBlinkRate = blinkRates.isEmpty ? 0.5 : blinkRates.reduce(0, +) / Float(blinkRates.count)
        let stdDevBlinkRate = computeStdDev(values: blinkRates, mean: meanBlinkRate)

        // Compute response duration statistics
        let meanResponseDuration = responseDurations.isEmpty ? 2.0 : responseDurations.reduce(0, +) / Double(responseDurations.count)
        let stdDevResponseDuration = computeStdDev(values: responseDurations.map { Float($0) }, mean: Float(meanResponseDuration))

        // Compute gaze stability statistics
        let meanGazeStability = gazeStabilities.isEmpty ? 0.5 : gazeStabilities.reduce(0, +) / Float(gazeStabilities.count)
        let stdDevGazeStability = computeStdDev(values: gazeStabilities, mean: meanGazeStability)

        // Compute blendshape baselines for key facial features
        let blendshapeBaselines = computeBlendshapeBaselines(from: allSamples)

        return FacialBaseline(
            blinkRateMean: meanBlinkRate,
            blinkRateStdDev: stdDevBlinkRate,
            gazeStabilityMean: meanGazeStability,
            gazeStabilityStdDev: stdDevGazeStability,
            blendshapeBaselines: blendshapeBaselines,
            responseDurationMean: meanResponseDuration,
            responseDurationStdDev: TimeInterval(stdDevResponseDuration)
        )
    }

    /// Compute gaze stability from face samples
    /// Returns a value between 0 and 1, where 1 means perfectly stable gaze
    private func computeGazeStability(samples: [FaceSample]) -> Float {
        guard samples.count >= 2 else { return 0.5 }

        var totalDeviation: Float = 0
        for i in 1..<samples.count {
            let prev = samples[i-1].eulerAngles
            let curr = samples[i].eulerAngles
            // Compute angular change between frames (head movement)
            let pitchDiff = abs(curr.x - prev.x)
            let yawDiff = abs(curr.y - prev.y)
            totalDeviation += pitchDiff + yawDiff
        }

        let avgDeviation = totalDeviation / Float(samples.count - 1)
        // Normalize to 0-1 range (lower deviation = higher stability)
        // 0.5 radians (~29°) of average movement per frame would be very unstable
        return max(0, min(1, 1 - avgDeviation * 2))
    }

    /// Compute baseline statistics for key blendshapes that indicate stress/deception
    private func computeBlendshapeBaselines(from samples: [FaceSample]) -> [String: BlendshapeStats] {
        guard !samples.isEmpty else { return [:] }

        // Key blendshapes to track for lie detection
        let keyBlendshapeKeys: [String] = [
            "browInnerUp",      // Stress indicator
            "browOuterUpLeft",  // Asymmetric brow movement
            "browOuterUpRight",
            "eyeSquintLeft",    // Microexpression
            "eyeSquintRight",
            "mouthSmileLeft",   // Asymmetric smile (Duchenne vs fake)
            "mouthSmileRight",
            "jawOpen",          // Speaking pattern
            "cheekPuff",        // Tension indicator
            "noseSneerLeft",    // Contempt/disgust microexpression
            "noseSneerRight"
        ]

        var baselines: [String: BlendshapeStats] = [:]

        for key in keyBlendshapeKeys {
            // Extract values for this blendshape from all samples
            let values = samples.compactMap { sample -> Float? in
                // Find the blendshape location that matches this key
                for (location, value) in sample.blendShapes {
                    if location.rawValue == key {
                        return value.floatValue
                    }
                }
                return nil
            }

            if !values.isEmpty {
                let mean = values.reduce(0, +) / Float(values.count)
                let stdDev = computeStdDev(values: values, mean: mean)
                let maxVal = values.max() ?? 0
                baselines[key] = BlendshapeStats(mean: mean, stdDev: stdDev, max: maxVal)
            }
        }

        return baselines
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
    
    private func computeStdDev(values: [Float], mean: Float) -> Float {
        guard !values.isEmpty else { return 0 }
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
        return sqrt(variance)
    }
    
    // MARK: - Cleanup

    func cleanup() {
        guard !isCleanedUp else { return }
        isCleanedUp = true
        faceTrackingService.stopTracking()
        speechService.stopListening()
    }
}

// MARK: - Supporting Types

enum CalibrationPhase {
    case intro          // Introduction screen
    case faceSetup      // Camera preview with face positioning guide
    case prepare        // Pre-question preparation
    case countdown      // 3-2-1 countdown
    case readQuestion   // Show question for user to read (no recording)
    case answer         // Recording phase - question at top, camera preview, listening
    case wrongAnswer    // User gave wrong answer, must retry
    case complete       // All questions done
}

struct QuestionResponse {
    let question: CalibrationQuestion
    let spokenAnswer: SpokenAnswer
    let faceSamples: [FaceSample]
    let responseDuration: TimeInterval
}
