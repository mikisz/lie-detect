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
    
    func proceedToNextQuestion() {
        if currentQuestionIndex < questions.count {
            currentPhase = .prepare
        } else {
            currentPhase = .complete
        }
    }
    
    func startQuestionRecording() {
        currentPhase = .countdown
        
        // After countdown, move to question
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showQuestion()
        }
    }
    
    func showQuestion() {
        currentPhase = .question
        
        // Start face tracking recording
        faceTrackingService.startRecording()
        
        let questionStartTime = Date()
        
        // Start listening for answer
        speechService.startListening { [weak self] answer in
            guard let self = self else { return }
            
            let responseDuration = Date().timeIntervalSince(questionStartTime)
            
            // Stop recording face data
            let faceSamples = self.faceTrackingService.stopRecording()
            
            // Store response
            if let question = self.currentQuestion {
                let response = QuestionResponse(
                    question: question,
                    spokenAnswer: answer,
                    faceSamples: faceSamples,
                    responseDuration: responseDuration
                )
                self.questionResponses.append(response)
                
                print("✅ Recorded answer '\(answer.rawValue)' for question \(self.currentQuestionIndex + 1)")
            }
            
            // Move to next question
            self.currentQuestionIndex += 1
            self.proceedToNextQuestion()
        }
    }
    
    func finishCalibration() -> CalibrationData? {
        print("🎉 Calibration complete! Processing data...")
        
        // Separate responses by answer type
        let yesResponses = questionResponses.filter { $0.spokenAnswer == .yes }
        let noResponses = questionResponses.filter { $0.spokenAnswer == .no }
        
        // Compute baselines (stubbed for now - will be enhanced later)
        let yesBaseline = computeBaseline(from: yesResponses)
        let noBaseline = computeBaseline(from: noResponses)
        
        let calibrationData = CalibrationData(
            playerID: player.id,
            calibratedAt: Date(),
            yesBaseline: yesBaseline,
            noBaseline: noBaseline,
            sampleCount: questionResponses.count,
            averageFaceConfidence: 0.85 // TODO: compute from actual data
        )
        
        return calibrationData
    }
    
    // MARK: - Baseline Computation (Stub)
    
    private func computeBaseline(from responses: [QuestionResponse]) -> FacialBaseline {
        // TODO: Implement real analysis
        // For now, return stub data
        
        var blinkRates: [Float] = []
        var responseDurations: [TimeInterval] = []
        
        for response in responses {
            // Count blinks in samples
            let blinkCount = countBlinks(in: response.faceSamples)
            let duration = response.faceSamples.last?.timestamp ?? 1.0
            let blinkRate = Float(blinkCount) / Float(duration)
            blinkRates.append(blinkRate)
            
            responseDurations.append(response.responseDuration)
        }
        
        let meanBlinkRate = blinkRates.isEmpty ? 0.5 : blinkRates.reduce(0, +) / Float(blinkRates.count)
        let stdDevBlinkRate = computeStdDev(values: blinkRates, mean: meanBlinkRate)
        
        let meanResponseDuration = responseDurations.isEmpty ? 2.0 : responseDurations.reduce(0, +) / Double(responseDurations.count)
        let stdDevResponseDuration = computeStdDev(values: responseDurations.map { Float($0) }, mean: Float(meanResponseDuration))
        
        return FacialBaseline(
            blinkRateMean: meanBlinkRate,
            blinkRateStdDev: stdDevBlinkRate,
            gazeStabilityMean: 0.3, // TODO: compute
            gazeStabilityStdDev: 0.1,
            blendshapeBaselines: [:], // TODO: populate
            responseDurationMean: meanResponseDuration,
            responseDurationStdDev: TimeInterval(stdDevResponseDuration)
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
    
    private func computeStdDev(values: [Float], mean: Float) -> Float {
        guard !values.isEmpty else { return 0 }
        
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Float(values.count)
        return sqrt(variance)
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        faceTrackingService.stopTracking()
        speechService.stopListening()
    }
}

// MARK: - Supporting Types

enum CalibrationPhase {
    case intro          // Introduction screen
    case prepare        // Pre-question preparation
    case countdown      // 3-2-1 countdown
    case question       // Showing question, recording answer
    case complete       // All questions done
}

struct QuestionResponse {
    let question: CalibrationQuestion
    let spokenAnswer: SpokenAnswer
    let faceSamples: [FaceSample]
    let responseDuration: TimeInterval
}
