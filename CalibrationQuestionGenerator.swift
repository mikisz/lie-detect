//
//  CalibrationQuestionGenerator.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation

/// Generates personalized calibration questions based on player profile
struct CalibrationQuestionGenerator {
    
    /// Generate calibration questions for a specific player
    static func generateQuestions(for player: Player) -> [CalibrationQuestion] {
        let calendar = Calendar.current
        let now = Date()
        
        // Get current date info
        let dayOfWeek = calendar.component(.weekday, from: now)
        let dayName = dayOfWeekName(for: dayOfWeek)
        
        let monthIndex = calendar.component(.month, from: now)
        let wrongMonth = wrongMonthName(excluding: monthIndex)
        
        _ = calendar.component(.year, from: now)
        
        return [
            // Expected YES answers (4 questions)
            CalibrationQuestion(
                text: "Czy masz na imię \(player.name)?",
                expectedAnswer: .yes,
                category: .identity
            ),
            CalibrationQuestion(
                text: "Czy jesteś \(player.gender.polishNominative)?",
                expectedAnswer: .yes,
                category: .identity
            ),
            CalibrationQuestion(
                text: "Czy widzisz teraz ekran telefonu?",
                expectedAnswer: .yes,
                category: .environment
            ),
            CalibrationQuestion(
                text: "Czy dzisiaj jest \(dayName)?",
                expectedAnswer: .yes,
                category: .temporal
            ),
            
            // Expected NO answers (4 questions)
            CalibrationQuestion(
                text: "Czy masz \(player.age + 5) lat?",
                expectedAnswer: .no,
                category: .identity
            ),
            CalibrationQuestion(
                text: "Czy jesteś \(player.gender.opposite.polishNominative)?",
                expectedAnswer: .no,
                category: .identity
            ),
            CalibrationQuestion(
                text: "Czy teraz śpisz?",
                expectedAnswer: .no,
                category: .environment
            ),
            CalibrationQuestion(
                text: "Czy jest teraz \(wrongMonth)?",
                expectedAnswer: .no,
                category: .temporal
            )
        ].shuffled() // Shuffle so it's not always yes-yes-yes-yes-no-no-no-no
    }
    
    // MARK: - Helper Functions
    
    private static func dayOfWeekName(for weekday: Int) -> String {
        let dayNames = [
            "", // Sunday is 1, so we start with empty
            "niedziela",
            "poniedziałek",
            "wtorek",
            "środa",
            "czwartek",
            "piątek",
            "sobota"
        ]
        return dayNames[weekday]
    }
    
    private static func wrongMonthName(excluding currentMonth: Int) -> String {
        let monthNames = [
            "styczeń", "luty", "marzec", "kwiecień", "maj", "czerwiec",
            "lipiec", "sierpień", "wrzesień", "październik", "listopad", "grudzień"
        ]
        
        // Get a wrong month (at least 3 months away from current)
        var wrongMonthIndex = (currentMonth + 6) % 12
        if wrongMonthIndex == 0 {
            wrongMonthIndex = 12
        }
        
        return monthNames[wrongMonthIndex - 1]
    }
}

// MARK: - CalibrationQuestion Model

struct CalibrationQuestion: Identifiable {
    let id = UUID()
    let text: String
    let expectedAnswer: SpokenAnswer
    let category: Category
    
    enum Category {
        case identity    // About the person
        case environment // About surroundings
        case temporal    // About time/date
    }
}

// MARK: - Gender Extension for Polish Grammar

extension Gender {
    /// Polish nominative form (mianownik) for "you are" questions
    var polishNominative: String {
        switch self {
        case .male: return "mężczyzną"
        case .female: return "kobietą"
        case .other: return "osobą niebinarną"
        }
    }
}
