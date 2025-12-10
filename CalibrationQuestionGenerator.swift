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
        let dayName = localizedDayOfWeekName(for: dayOfWeek)

        let monthIndex = calendar.component(.month, from: now)
        let wrongMonth = localizedWrongMonthName(excluding: monthIndex)

        _ = calendar.component(.year, from: now)

        return [
            // Expected YES answers (4 questions)
            CalibrationQuestion(
                text: String(format: "calibration.q.is_your_name".localized, player.name),
                expectedAnswer: .yes,
                category: .identity
            ),
            CalibrationQuestion(
                text: String(format: "calibration.q.are_you_gender".localized, player.gender.localizedNominative),
                expectedAnswer: .yes,
                category: .identity
            ),
            CalibrationQuestion(
                text: "calibration.q.can_see_screen".localized,
                expectedAnswer: .yes,
                category: .environment
            ),
            CalibrationQuestion(
                text: String(format: "calibration.q.is_today".localized, dayName),
                expectedAnswer: .yes,
                category: .temporal
            ),

            // Expected NO answers (4 questions)
            CalibrationQuestion(
                text: String(format: "calibration.q.are_you_age".localized, player.age + 5),
                expectedAnswer: .no,
                category: .identity
            ),
            CalibrationQuestion(
                text: String(format: "calibration.q.are_you_opposite_gender".localized, player.gender.opposite.localizedNominative),
                expectedAnswer: .no,
                category: .identity
            ),
            CalibrationQuestion(
                text: "calibration.q.are_you_sleeping".localized,
                expectedAnswer: .no,
                category: .environment
            ),
            CalibrationQuestion(
                text: String(format: "calibration.q.is_month".localized, wrongMonth),
                expectedAnswer: .no,
                category: .temporal
            )
        ].shuffled() // Shuffle so it's not always yes-yes-yes-yes-no-no-no-no
    }

    // MARK: - Helper Functions

    private static func localizedDayOfWeekName(for weekday: Int) -> String {
        let dayKeys = [
            "", // Sunday is 1, so we start with empty
            "day.sunday",
            "day.monday",
            "day.tuesday",
            "day.wednesday",
            "day.thursday",
            "day.friday",
            "day.saturday"
        ]
        return dayKeys[weekday].localized
    }

    private static func localizedWrongMonthName(excluding currentMonth: Int) -> String {
        let monthKeys = [
            "month.january", "month.february", "month.march", "month.april",
            "month.may", "month.june", "month.july", "month.august",
            "month.september", "month.october", "month.november", "month.december"
        ]

        // Get a wrong month (at least 3 months away from current)
        var wrongMonthIndex = (currentMonth + 6) % 12
        if wrongMonthIndex == 0 {
            wrongMonthIndex = 12
        }

        return monthKeys[wrongMonthIndex - 1].localized
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

// MARK: - Gender Extension for Localized Grammar

extension Gender {
    /// Localized nominative form for "you are" questions
    var localizedNominative: String {
        switch self {
        case .male: return "gender.male_nominative".localized
        case .female: return "gender.female_nominative".localized
        case .other: return "gender.other_nominative".localized
        }
    }

    /// Polish nominative form (mianownik) for "you are" questions (legacy)
    var polishNominative: String {
        switch self {
        case .male: return "mężczyzną"
        case .female: return "kobietą"
        case .other: return "osobą niebinarną"
        }
    }
}
