//
//  FaceTrackingService.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import ARKit
import SceneKit

/// Service responsible for managing ARKit face tracking session
@Observable
class FaceTrackingService: NSObject {
    // MARK: - Observable Properties
    var isFaceDetected = false
    var faceQuality: FaceQuality = .unknown
    var isTracking = false
    var currentBlendShapes: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]

    // MARK: - ARSCNView for camera preview
    let sceneView: ARSCNView = {
        let view = ARSCNView()
        view.automaticallyUpdatesLighting = true
        view.rendersCameraGrain = false
        view.rendersMotionBlur = false
        return view
    }()

    // MARK: - Private Properties
    private var faceAnchor: ARFaceAnchor?

    // Recording state - use serial queue for thread safety
    private let recordingQueue = DispatchQueue(label: "com.liedetect.facetracking.recording")
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

        sceneView.session.delegate = self
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        isTracking = true
        print("✅ Face tracking started")
    }

    /// Stop the AR session
    func stopTracking() {
        sceneView.session.pause()
        isTracking = false
        isFaceDetected = false
        faceQuality = .unknown
        print("⏸️ Face tracking stopped")
    }
    
    /// Start recording facial data samples
    func startRecording() {
        guard isTracking else { return }

        recordingQueue.sync {
            isRecording = true
            recordedSamples = []
            recordingStartTime = Date()
        }
        print("🎬 Started recording facial data")
    }

    /// Stop recording and return collected samples
    func stopRecording() -> [FaceSample] {
        var samples: [FaceSample] = []
        recordingQueue.sync {
            isRecording = false
            samples = recordedSamples
            recordedSamples = []
            recordingStartTime = nil
        }
        print("⏹️ Stopped recording. Collected \(samples.count) samples")
        return samples
    }
    
    /// Get current face quality assessment
    func assessFaceQuality(anchor: ARFaceAnchor) -> FaceQuality {
        // Check if face is roughly centered (within reasonable bounds)
        // Position is in meters from camera origin - typically face is 0.3-0.6m away
        let position = anchor.transform.columns.3

        // X: left/right offset (negative = left, positive = right)
        // Y: up/down offset (negative = down, positive = up)
        // More lenient thresholds - 0.12m is about 12cm offset
        let xOffset = abs(position.x)
        let yOffset = abs(position.y)

        let isCentered = xOffset < 0.12 && yOffset < 0.12        // Well centered (relaxed from 8cm to 12cm)
        let isReasonablyCentered = xOffset < 0.18 && yOffset < 0.18  // Acceptable

        // Check rotation (pitch, yaw, roll in radians)
        // 0.35 radians ≈ 20 degrees, 0.5 radians ≈ 29 degrees
        let eulerAngles = anchor.transform.eulerAngles
        let pitch = abs(eulerAngles.x)  // Looking up/down
        let yaw = abs(eulerAngles.y)    // Turning left/right
        let roll = abs(eulerAngles.z)   // Tilting head

        let isFacingCamera = pitch < 0.35 && yaw < 0.35 && roll < 0.35       // Looking straight (relaxed from 14° to 20°)
        let isReasonablyFacing = pitch < 0.52 && yaw < 0.52 && roll < 0.52   // Acceptable angle (~30°)

        // Overall quality assessment
        if isCentered && isFacingCamera {
            return .good
        } else if isReasonablyCentered && isReasonablyFacing {
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
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        self.faceAnchor = faceAnchor

        DispatchQueue.main.async {
            self.isFaceDetected = true
            self.faceQuality = self.assessFaceQuality(anchor: faceAnchor)
            self.currentBlendShapes = faceAnchor.blendShapes
            print("👤 Face detected")
        }
    }

    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.compactMap({ $0 as? ARFaceAnchor }).first else { return }

        self.faceAnchor = faceAnchor

        DispatchQueue.main.async {
            self.isFaceDetected = faceAnchor.isTracked
            self.faceQuality = faceAnchor.isTracked ? self.assessFaceQuality(anchor: faceAnchor) : .unknown
            self.currentBlendShapes = faceAnchor.blendShapes
        }

        // Record sample if we're recording (thread-safe)
        recordingQueue.async { [weak self] in
            guard let self = self,
                  self.isRecording,
                  faceAnchor.isTracked,
                  let startTime = self.recordingStartTime else { return }

            let sample = FaceSample(
                timestamp: Date().timeIntervalSince(startTime),
                blendShapes: faceAnchor.blendShapes,
                transform: faceAnchor.transform
            )
            self.recordedSamples.append(sample)
        }
    }

    func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
        let removedFace = anchors.contains { $0 is ARFaceAnchor }
        if removedFace {
            self.faceAnchor = nil
            DispatchQueue.main.async {
                self.isFaceDetected = false
                self.faceQuality = .unknown
                print("👤 Face lost")
            }
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        print("❌ AR Session failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.isTracking = false
            self.isFaceDetected = false
            self.faceQuality = .unknown
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
        case .fair: return "Prawie dobrze - wyśrodkuj twarz"
        case .good: return "Doskonale!"
        }
    }

    var localizedMessage: String {
        switch self {
        case .unknown: return "face.quality.unknown".localized
        case .poor: return "face.quality.poor".localized
        case .fair: return "face.quality.fair".localized
        case .good: return "face.quality.good".localized
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

    // Eye gaze blendshapes for precise gaze direction tracking
    var eyeLookInLeft: Float { blendShapes[.eyeLookInLeft]?.floatValue ?? 0 }
    var eyeLookInRight: Float { blendShapes[.eyeLookInRight]?.floatValue ?? 0 }
    var eyeLookOutLeft: Float { blendShapes[.eyeLookOutLeft]?.floatValue ?? 0 }
    var eyeLookOutRight: Float { blendShapes[.eyeLookOutRight]?.floatValue ?? 0 }
    var eyeLookUpLeft: Float { blendShapes[.eyeLookUpLeft]?.floatValue ?? 0 }
    var eyeLookUpRight: Float { blendShapes[.eyeLookUpRight]?.floatValue ?? 0 }
    var eyeLookDownLeft: Float { blendShapes[.eyeLookDownLeft]?.floatValue ?? 0 }
    var eyeLookDownRight: Float { blendShapes[.eyeLookDownRight]?.floatValue ?? 0 }

    // Additional stress/microexpression indicators
    var browOuterUpLeft: Float { blendShapes[.browOuterUpLeft]?.floatValue ?? 0 }
    var browOuterUpRight: Float { blendShapes[.browOuterUpRight]?.floatValue ?? 0 }
    var eyeSquintLeft: Float { blendShapes[.eyeSquintLeft]?.floatValue ?? 0 }
    var eyeSquintRight: Float { blendShapes[.eyeSquintRight]?.floatValue ?? 0 }
    var mouthSmileLeft: Float { blendShapes[.mouthSmileLeft]?.floatValue ?? 0 }
    var mouthSmileRight: Float { blendShapes[.mouthSmileRight]?.floatValue ?? 0 }
    var cheekPuff: Float { blendShapes[.cheekPuff]?.floatValue ?? 0 }
    var noseSneerLeft: Float { blendShapes[.noseSneerLeft]?.floatValue ?? 0 }
    var noseSneerRight: Float { blendShapes[.noseSneerRight]?.floatValue ?? 0 }

    /// Computed horizontal gaze direction (-1 = looking left, 0 = center, 1 = looking right)
    var horizontalGaze: Float {
        let leftEyeHorizontal = eyeLookOutLeft - eyeLookInLeft
        let rightEyeHorizontal = eyeLookInRight - eyeLookOutRight
        return (leftEyeHorizontal + rightEyeHorizontal) / 2
    }

    /// Computed vertical gaze direction (-1 = looking down, 0 = center, 1 = looking up)
    var verticalGaze: Float {
        let leftEyeVertical = eyeLookUpLeft - eyeLookDownLeft
        let rightEyeVertical = eyeLookUpRight - eyeLookDownRight
        return (leftEyeVertical + rightEyeVertical) / 2
    }

    /// Smile asymmetry (0 = symmetric, higher = more asymmetric)
    var smileAsymmetry: Float {
        abs(mouthSmileLeft - mouthSmileRight)
    }

    /// Brow asymmetry (0 = symmetric, higher = more asymmetric)
    var browAsymmetry: Float {
        abs(browOuterUpLeft - browOuterUpRight)
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

// MARK: - SwiftUI Camera Preview
import SwiftUI

/// SwiftUI wrapper for ARSCNView camera preview
struct ARCameraPreview: UIViewRepresentable {
    let faceTrackingService: FaceTrackingService

    func makeUIView(context: Context) -> ARSCNView {
        let view = faceTrackingService.sceneView
        view.backgroundColor = .black
        return view
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No updates needed - the session manages itself
    }
}
