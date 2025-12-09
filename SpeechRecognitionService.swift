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

/// Service responsible for speech recognition of "tak" and "nie" responses
class SpeechRecognitionService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var isListening = false
    @Published var recognizedText: String = ""
    @Published var detectedAnswer: SpokenAnswer?
    @Published var confidence: Float = 0.0
    
    // MARK: - Private Properties
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "pl-PL"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    
    private var answerDetectionCallback: ((SpokenAnswer) -> Void)?
    
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
    
    /// Start listening for "tak" or "nie"
    func startListening(onAnswerDetected: @escaping (SpokenAnswer) -> Void) {
        guard isAuthorized else {
            print("❌ Speech recognition not authorized")
            return
        }
        
        // Stop any existing task
        if isListening {
            stopListening()
        }
        
        answerDetectionCallback = onAnswerDetected
        
        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("❌ Audio session setup failed: \(error)")
            return
        }
        
        // Create and configure recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("❌ Unable to create recognition request")
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
            print("❌ Audio engine failed to start: \(error)")
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
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        
        DispatchQueue.main.async {
            self.isListening = false
        }
        
        print("⏹️ Stopped listening")
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
