//
//  QuestionPackManager.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import Foundation
import SwiftUI

/// Service responsible for loading and managing question packs
@Observable
class QuestionPackManager {
    // MARK: - Singleton
    static let shared = QuestionPackManager()

    // MARK: - Properties
    private(set) var packs: [QuestionPack] = []
    private(set) var isLoaded = false

    // MARK: - Initialization
    private init() {
        loadPacks()
    }

    // MARK: - Public Methods

    /// Get all available packs
    func getAllPacks() -> [QuestionPack] {
        return packs
    }

    /// Get free packs only
    func getFreePacks() -> [QuestionPack] {
        return packs.filter { !$0.isPremium }
    }

    /// Get premium packs only
    func getPremiumPacks() -> [QuestionPack] {
        return packs.filter { $0.isPremium }
    }

    /// Get packs by category
    func getPacks(for category: PackCategory) -> [QuestionPack] {
        return packs.filter { $0.category == category }
    }

    /// Get a specific pack by ID
    func getPack(id: String) -> QuestionPack? {
        return packs.first { $0.id == id }
    }

    /// Reload packs from JSON
    func reloadPacks() {
        loadPacks()
    }

    // MARK: - Private Methods

    private func loadPacks() {
        // Try to load from JSON file in bundle
        guard let url = Bundle.main.url(forResource: "packs", withExtension: "json") else {
            print("⚠️ packs.json not found in bundle, using fallback pack")
            loadFallbackPack()
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let container = try decoder.decode(PacksContainer.self, from: data)
            self.packs = container.packs
            self.isLoaded = true
            print("✅ Loaded \(packs.count) question pack(s) from packs.json")
        } catch {
            print("❌ Failed to load packs.json: \(error)")
            loadFallbackPack()
        }
    }

    private func loadFallbackPack() {
        // Create a minimal fallback pack if JSON fails to load
        let fallbackPack = QuestionPack(
            id: "fallback",
            name: LocalizedString(pl: "Pakiet podstawowy", en: "Basic Pack"),
            description: LocalizedString(pl: "Podstawowe pytania", en: "Basic questions"),
            emoji: "🎯",
            imageName: nil,
            category: .general,
            questions: [
                PackQuestion(
                    id: "fallback_1",
                    text: LocalizedString(
                        pl: "Czy kiedykolwiek skłamałeś/aś?",
                        en: "Have you ever lied?"
                    ),
                    difficulty: .easy
                ),
                PackQuestion(
                    id: "fallback_2",
                    text: LocalizedString(
                        pl: "Czy masz jakiś sekret?",
                        en: "Do you have a secret?"
                    ),
                    difficulty: .easy
                ),
                PackQuestion(
                    id: "fallback_3",
                    text: LocalizedString(
                        pl: "Czy żałujesz czegoś z przeszłości?",
                        en: "Do you regret something from your past?"
                    ),
                    difficulty: .medium
                ),
                PackQuestion(
                    id: "fallback_4",
                    text: LocalizedString(
                        pl: "Czy kiedykolwiek udawałeś/aś chorobę?",
                        en: "Have you ever faked being sick?"
                    ),
                    difficulty: .easy
                ),
                PackQuestion(
                    id: "fallback_5",
                    text: LocalizedString(
                        pl: "Czy sprawdzałeś/aś czyjś telefon bez pozwolenia?",
                        en: "Have you ever checked someone's phone without permission?"
                    ),
                    difficulty: .medium
                )
            ],
            isPremium: false,
            version: "1.0"
        )

        self.packs = [fallbackPack]
        self.isLoaded = true
        print("⚠️ Using fallback pack with \(fallbackPack.questions.count) questions")
    }
}

// MARK: - SwiftUI Environment Key

struct QuestionPackManagerKey: EnvironmentKey {
    static let defaultValue = QuestionPackManager.shared
}

extension EnvironmentValues {
    var questionPackManager: QuestionPackManager {
        get { self[QuestionPackManagerKey.self] }
        set { self[QuestionPackManagerKey.self] = newValue }
    }
}
