//
//  CalibrationData.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation

struct CalibrationData: Codable {
    let playerID: UUID
    let calibratedAt: Date
    
    // Baselines for "tak" (yes)
    let yesBaseline: FacialBaseline
    
    // Baselines for "nie" (no)
    let noBaseline: FacialBaseline
    
    // Metadata about calibration session
    let sampleCount: Int
    let averageFaceConfidence: Float
}

struct FacialBaseline: Codable {
    // Aggregated statistics from calibration samples
    let blinkRateMean: Float
    let blinkRateStdDev: Float
    
    let gazeStabilityMean: Float
    let gazeStabilityStdDev: Float
    
    // Selected blendshape baselines
    let blendshapeBaselines: [String: BlendshapeStats]
    
    // Speaking duration baseline
    let responseDurationMean: TimeInterval
    let responseDurationStdDev: TimeInterval
}

struct BlendshapeStats: Codable {
    let mean: Float
    let stdDev: Float
    let max: Float
}
