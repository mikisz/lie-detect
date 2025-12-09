//
//  FaceTrackingService.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import ARKit
import Combine

/// Service responsible for managing ARKit face tracking session
class FaceTrackingService: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isFaceDetected = false
    @Published var faceQuality: FaceQuality = .unknown
    @Published var isTracking = false
    @Published var currentBlendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
    
    // MARK: - Private Properties
    private var arSession: ARSession?
    private var faceAnchor: ARFaceAnchor?
    
    // Recording state
    private var isRecording = false
    private var recordedSamples: [FaceSample] = []
    private var recordingStartTime: Date?
    
    // MARK: - Initialization
    override init() {
        super.init()
        _ = checkARSupport()
    }
    
    // MARK: - Public Methods
    
    /// Check if device supports ARKit face tracking
    func checkARSupport() -> Bool {
        return ARFaceTrackingConfiguration.isSupported
    }
    
    /// Start the AR session for face tracking
    func startTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            print("❌ ARKit face tracking not supported on this device")
            return
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        
        arSession = ARSession()
        arSession?.delegate = self
        arSession?.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        isTracking = true
        print("✅ Face tracking started")
    }
    
    /// Stop the AR session
    func stopTracking() {
        arSession?.pause()
        isTracking = false
        isFaceDetected = false
        faceQuality = .unknown
        print("⏸️ Face tracking stopped")
    }
    
    /// Start recording facial data samples
    func startRecording() {
        guard isTracking else { return }
        
        isRecording = true
        recordedSamples = []
        recordingStartTime = Date()
        print("🎬 Started recording facial data")
    }
    
    /// Stop recording and return collected samples
    func stopRecording() -> [FaceSample] {
        isRecording = false
        let samples = recordedSamples
        recordedSamples = []
        recordingStartTime = nil
        print("⏹️ Stopped recording. Collected \(samples.count) samples")
        return samples
    }
    
    /// Get current face quality assessment
    func assessFaceQuality(anchor: ARFaceAnchor) -> FaceQuality {
        // Check if face is roughly centered (within reasonable bounds)
        let position = anchor.transform.columns.3
        let isReasonablyCentered = abs(position.x) < 0.2 && abs(position.y) < 0.2
        
        // Check rotation (pitch, yaw, roll should be reasonable)
        let eulerAngles = anchor.transform.eulerAngles
        let pitch = abs(eulerAngles.x)
        let yaw = abs(eulerAngles.y)
        let roll = abs(eulerAngles.z)
        
        let isReasonablyFacingCamera = pitch < 0.5 && yaw < 0.5 && roll < 0.5
        
        // Overall quality
        if isReasonablyCentered && isReasonablyFacingCamera {
            return .good
        } else if isReasonablyCentered || isReasonablyFacingCamera {
            return .fair
        } else {
            return .poor
        }
    }
    
    deinit {
        stopTracking()
    }
}

// MARK: - ARSessionDelegate
extension FaceTrackingService: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else {
            DispatchQueue.main.async {
                self.isFaceDetected = false
                self.faceQuality = .unknown
            }
            return
        }
        
        self.faceAnchor = faceAnchor
        
        DispatchQueue.main.async {
            self.isFaceDetected = true
            self.faceQuality = self.assessFaceQuality(anchor: faceAnchor)
            self.currentBlendShapes = faceAnchor.blendShapes
        }
        
        // Record sample if we're recording
        if isRecording, let startTime = recordingStartTime {
            let sample = FaceSample(
                timestamp: Date().timeIntervalSince(startTime),
                blendShapes: faceAnchor.blendShapes,
                transform: faceAnchor.transform
            )
            recordedSamples.append(sample)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR Session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isTracking = false
            self.isFaceDetected = false
        }
    }
}

// MARK: - Supporting Types

enum FaceQuality {
    case unknown
    case poor      // Face not centered or at bad angle
    case fair      // Face visible but not ideal
    case good      // Face well positioned
    
    var message: String {
        switch self {
        case .unknown: return "Przygotowanie..."
        case .poor: return "Spójrz prosto w kamerę"
        case .fair: return "Wyśrodkuj twarz"
        case .good: return "Doskonale!"
        }
    }
    
    var color: String {
        switch self {
        case .unknown: return "gray"
        case .poor: return "red"
        case .fair: return "orange"
        case .good: return "green"
        }
    }
}

struct FaceSample {
    let timestamp: TimeInterval
    let blendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber]
    let transform: simd_float4x4
    
    // Computed properties for easy access to key features
    var eyeBlinkLeft: Float {
        blendShapes[.eyeBlinkLeft]?.floatValue ?? 0
    }
    
    var eyeBlinkRight: Float {
        blendShapes[.eyeBlinkRight]?.floatValue ?? 0
    }
    
    var browInnerUp: Float {
        blendShapes[.browInnerUp]?.floatValue ?? 0
    }
    
    var jawOpen: Float {
        blendShapes[.jawOpen]?.floatValue ?? 0
    }
    
    var eulerAngles: simd_float3 {
        transform.eulerAngles
    }
}

// MARK: - simd_float4x4 Extension
extension simd_float4x4 {
    var eulerAngles: simd_float3 {
        // Extract rotation from transform matrix
        let pitch = atan2(self[2][1], self[2][2])
        let yaw = atan2(-self[2][0], sqrt(self[2][1] * self[2][1] + self[2][2] * self[2][2]))
        let roll = atan2(self[1][0], self[0][0])
        
        return simd_float3(pitch, yaw, roll)
    }
}
