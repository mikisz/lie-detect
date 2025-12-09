//
//  Player.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation
import SwiftData

@Model
final class Player {
    var id: UUID
    var name: String
    var age: Int
    var gender: Gender
    var profileImageData: Data?
    var calibrationData: CalibrationData?
    var createdAt: Date
    var lastCalibratedAt: Date?
    
    init(
        id: UUID = UUID(),
        name: String,
        age: Int,
        gender: Gender,
        profileImageData: Data? = nil,
        calibrationData: CalibrationData? = nil,
        createdAt: Date = Date(),
        lastCalibratedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.age = age
        self.gender = gender
        self.profileImageData = profileImageData
        self.calibrationData = calibrationData
        self.createdAt = createdAt
        self.lastCalibratedAt = lastCalibratedAt
    }
    
    var isCalibrated: Bool {
        calibrationData != nil
    }
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        let firstInitial = components.first?.first.map(String.init) ?? ""
        let lastInitial = components.count > 1 ? components.last?.first.map(String.init) ?? "" : ""
        return (firstInitial + lastInitial).uppercased()
    }
}

enum Gender: String, Codable, CaseIterable {
    case male = "Mężczyzna"
    case female = "Kobieta"
    case other = "Inna"
    
    var opposite: Gender {
        switch self {
        case .male: return .female
        case .female: return .male
        case .other: return .male
        }
    }
    
    var emoji: String {
        switch self {
        case .male: return "👨"
        case .female: return "👩"
        case .other: return "🧑"
        }
    }
}
