//
//  QuestionPack.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import Foundation
import SwiftUI

// MARK: - Localized String

/// A string that supports multiple languages
struct LocalizedString: Codable, Equatable {
    let pl: String
    let en: String

    /// Returns the string in the current app language
    var localized: String {
        LocalizationManager.shared.currentLanguage == .polish ? pl : en
    }

    init(pl: String, en: String) {
        self.pl = pl
        self.en = en
    }

    // Convenience initializer for same text in both languages
    init(_ text: String) {
        self.pl = text
        self.en = text
    }
}

// MARK: - Question Pack

/// A themed collection of questions
struct QuestionPack: Identifiable, Codable, Equatable {
    let id: String
    let name: LocalizedString
    let description: LocalizedString
    let emoji: String
    let imageName: String?           // Optional image asset name
    let category: PackCategory
    let questions: [PackQuestion]
    let isPremium: Bool
    let version: String

    /// Number of questions in the pack
    var questionCount: Int {
        questions.count
    }

    /// Localized name for display
    var localizedName: String {
        name.localized
    }

    /// Localized description for display
    var localizedDescription: String {
        description.localized
    }
}

// MARK: - Pack Question

/// A single question within a pack
struct PackQuestion: Identifiable, Codable, Equatable {
    let id: String
    let text: LocalizedString
    let difficulty: QuestionDifficulty

    /// Localized question text for display
    var localizedText: String {
        text.localized
    }
}

// MARK: - Enums

enum PackCategory: String, Codable, CaseIterable {
    case general = "general"
    case spicy = "spicy"
    case relationships = "relationships"
    case secrets = "secrets"
    case party = "party"

    var localizedName: String {
        switch self {
        case .general: return "pack.category.general".localized
        case .spicy: return "pack.category.spicy".localized
        case .relationships: return "pack.category.relationships".localized
        case .secrets: return "pack.category.secrets".localized
        case .party: return "pack.category.party".localized
        }
    }

    var emoji: String {
        switch self {
        case .general: return "🎯"
        case .spicy: return "🌶️"
        case .relationships: return "❤️"
        case .secrets: return "🤫"
        case .party: return "🎉"
        }
    }
}

enum QuestionDifficulty: String, Codable, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var localizedName: String {
        switch self {
        case .easy: return "difficulty.easy".localized
        case .medium: return "difficulty.medium".localized
        case .hard: return "difficulty.hard".localized
        }
    }

    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Game Configuration

/// Configuration for a game session
struct GameConfiguration {
    let pack: QuestionPack
    let questionCount: Int                    // 5, 10, or 15
    let selectionMode: QuestionSelectionMode
    let verdictMode: VerdictMode
    let selectedQuestionIds: [String]?        // For manual mode only

    /// Get the questions to use in the game based on configuration
    func getQuestions() -> [PackQuestion] {
        switch selectionMode {
        case .random:
            return Array(pack.questions.shuffled().prefix(questionCount))
        case .manual:
            guard let selectedIds = selectedQuestionIds else {
                return Array(pack.questions.prefix(questionCount))
            }
            return pack.questions.filter { selectedIds.contains($0.id) }
        }
    }

    /// Convert PackQuestions to GameQuestions for the game session
    func getGameQuestions() -> [GameQuestion] {
        getQuestions().map { packQuestion in
            GameQuestion(
                text: packQuestion.localizedText,
                category: pack.category.toQuestionCategory()
            )
        }
    }
}

enum QuestionSelectionMode: String, CaseIterable {
    case random = "random"
    case manual = "manual"

    var localizedName: String {
        switch self {
        case .random: return "selection.random".localized
        case .manual: return "selection.manual".localized
        }
    }

    var icon: String {
        switch self {
        case .random: return "shuffle"
        case .manual: return "hand.tap"
        }
    }

    var description: String {
        switch self {
        case .random: return "selection.random.description".localized
        case .manual: return "selection.manual.description".localized
        }
    }
}

enum VerdictMode: String, CaseIterable {
    case afterEach = "after_each"      // Mode A - verdict after each question
    case atEnd = "at_end"              // Mode B - all verdicts at the end

    var localizedName: String {
        switch self {
        case .afterEach: return "verdict.mode.after_each".localized
        case .atEnd: return "verdict.mode.at_end".localized
        }
    }

    var icon: String {
        switch self {
        case .afterEach: return "checkmark.circle"
        case .atEnd: return "list.bullet.clipboard"
        }
    }

    var description: String {
        switch self {
        case .afterEach: return "verdict.mode.after_each.description".localized
        case .atEnd: return "verdict.mode.at_end.description".localized
        }
    }

    var isAvailable: Bool {
        switch self {
        case .afterEach: return true
        case .atEnd: return false  // Not implemented yet
        }
    }
}

// MARK: - Extensions

extension PackCategory {
    func toQuestionCategory() -> QuestionCategory {
        switch self {
        case .general: return .general
        case .spicy: return .spicy
        case .relationships: return .relationships
        case .secrets: return .secrets
        case .party: return .general  // Map party to general for now
        }
    }
}

// MARK: - Packs Container (for JSON decoding)

struct PacksContainer: Codable {
    let packs: [QuestionPack]
}
