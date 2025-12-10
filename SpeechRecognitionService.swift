//
//  SpeechRecognitionService.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import Speech
import AVFoundation
import Combine

/// Result of speech recognition attempt
enum SpeechResult {
    case answer(SpokenAnswer)
    case timeout
    case error(String)
}

/// Service responsible for speech recognition of "tak" and "nie" responses
class SpeechRecognitionService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isListening = false
    @Published var recognizedText: String = ""
    @Published var detectedAnswer: SpokenAnswer?
    @Published var confidence: Float = 0.0
    @Published var didTimeout = false
    @Published var lastError: String? = nil

    /// Whether there's an error state
    var hasError: Bool { lastError != nil }

    /// Clear any error state
    func clearError() {
        lastError = nil
    }

    // MARK: - Configuration
    var timeoutDuration: TimeInterval = 10.0  // Default 10 seconds

    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    private var answerDetectionCallback: ((SpokenAnswer) -> Void)?
    private var resultCallback: ((SpeechResult) -> Void)?
    private var timeoutTimer: Timer?
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkAuthorization()
    }
    
    // MARK: - Authorization
    
    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                    print("✅ Speech recognition authorized")
                case .denied:
                    print("❌ Speech recognition denied")
                case .restricted:
                    print("❌ Speech recognition restricted")
                case .notDetermined:
                    print("⚠️ Speech recognition not determined")
                @unknown default:
                    print("❌ Unknown speech recognition status")
                }
            }
        }
    }
    
    // MARK: - Speech Recognition

    /// Start listening for "tak" or "nie" with timeout support
    /// - Parameters:
    ///   - timeout: Optional timeout duration. If nil, uses default timeoutDuration
    ///   - onResult: Callback with SpeechResult (answer, timeout, or error)
    func startListening(timeout: TimeInterval? = nil, onResult: @escaping (SpeechResult) -> Void) {
        guard isAuthorized else {
            print("❌ Speech recognition not authorized")
            onResult(.error("speech.not_authorized".localized))
            return
        }

        // Stop any existing task
        if isListening {
            stopListening()
        }

        didTimeout = false
        resultCallback = onResult

        // Also set legacy callback for compatibility
        answerDetectionCallback = { answer in
            onResult(.answer(answer))
        }

        // Start timeout timer
        let duration = timeout ?? timeoutDuration
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
            guard let self = self, self.isListening else { return }
            print("⏰ Speech recognition timeout after \(duration)s")
            DispatchQueue.main.async {
                self.didTimeout = true
                self.resultCallback?(.timeout)
                self.stopListening()
            }
        }

        startAudioRecognition()
    }

    /// Legacy method - Start listening for "tak" or "nie" (no timeout)
    func startListening(onAnswerDetected: @escaping (SpokenAnswer) -> Void) {
        guard isAuthorized else {
            print("❌ Speech recognition not authorized")
            return
        }

        // Stop any existing task
        if isListening {
            stopListening()
        }

        didTimeout = false
        answerDetectionCallback = onAnswerDetected

        startAudioRecognition()
    }

    /// Internal method to start the audio recognition engine
    private func startAudioRecognition() {
        // Clear any previous error
        lastError = nil

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            let errorMessage = "audio.setup_failed".localized
            print("❌ Audio session setup failed: \(error)")
            lastError = errorMessage
            resultCallback?(.error(errorMessage))
            return
        }

        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            let errorMessage = "speech.request_failed".localized
            print("❌ Unable to create recognition request")
            lastError = errorMessage
            resultCallback?(.error(errorMessage))
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // Configure audio engine
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            let errorMessage = "audio.engine_failed".localized
            print("❌ Audio engine failed to start: \(error)")
            lastError = errorMessage
            resultCallback?(.error(errorMessage))
            return
        }

        // Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                let transcript = result.bestTranscription.formattedString.lowercased()

                DispatchQueue.main.async {
                    self.recognizedText = transcript
                }

                // Check for "tak" or "nie"
                if let answer = self.detectAnswer(from: transcript) {
                    DispatchQueue.main.async {
                        self.detectedAnswer = answer
                        self.confidence = result.bestTranscription.segments.last?.confidence ?? 0.0

                        // Trigger callback
                        self.answerDetectionCallback?(answer)

                        // Stop listening after detection
                        self.stopListening()
                    }
                }
            }

            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }

        DispatchQueue.main.async {
            self.isListening = true
        }

        print("🎤 Started listening for speech")
    }
    
    /// Stop listening
    func stopListening() {
        // Cancel timeout timer
        timeoutTimer?.invalidate()
        timeoutTimer = nil

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        resultCallback = nil
        answerDetectionCallback = nil

        DispatchQueue.main.async {
            self.isListening = false
        }

        print("⏹️ Stopped listening")
    }

    /// Reset timeout state (call before retrying)
    func resetTimeout() {
        didTimeout = false
    }
    
    // MARK: - Answer Detection
    
    private func detectAnswer(from text: String) -> SpokenAnswer? {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check for "tak" (yes)
        if cleaned.contains("tak") || cleaned == "tak" {
            return .yes
        }
        
        // Check for "nie" (no)
        if cleaned.contains("nie") || cleaned == "nie" || cleaned.contains("nee") {
            return .no
        }
        
        return nil
    }
    
    deinit {
        stopListening()
    }
}

// MARK: - SpokenAnswer Enum
enum SpokenAnswer: String, Codable {
    case yes = "tak"
    case no = "nie"
    
    var displayText: String {
        switch self {
        case .yes: return "Tak"
        case .no: return "Nie"
        }
    }
}
