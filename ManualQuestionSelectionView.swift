//
//  ManualQuestionSelectionView.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import SwiftUI

/// View for manually selecting specific questions from a pack
struct ManualQuestionSelectionView: View {
    let pack: QuestionPack
    let requiredCount: Int
    let onConfirm: ([String]) -> Void
    let onBack: () -> Void

    @State private var selectedQuestionIds: Set<String> = []
    @State private var searchText = ""

    private var filteredQuestions: [PackQuestion] {
        if searchText.isEmpty {
            return pack.questions
        }
        return pack.questions.filter {
            $0.localizedText.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var canConfirm: Bool {
        selectedQuestionIds.count == requiredCount
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.1, blue: 0.2),
                    Color(red: 0.1, green: 0.15, blue: 0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Text("game.setup.choose_questions".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // Selection counter
                    HStack(spacing: 8) {
                        Text("\(selectedQuestionIds.count)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(canConfirm ? .green : .cyan)

                        Text("/")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.5))

                        Text("\(requiredCount)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))

                        Text("game.setup.selected".localized)
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.1))
                    )
                }
                .padding(.top, 20)
                .padding(.bottom, 16)

                // Search bar
                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.5))

                    TextField("game.setup.search".localized, text: $searchText)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.1))
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

                // Questions list
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredQuestions) { question in
                            QuestionSelectCard(
                                question: question,
                                isSelected: selectedQuestionIds.contains(question.id),
                                isDisabled: !selectedQuestionIds.contains(question.id) && selectedQuestionIds.count >= requiredCount
                            ) {
                                toggleQuestion(question.id)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120) // Space for buttons
                }

                // Bottom buttons
                VStack(spacing: 12) {
                    // Confirm button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        onConfirm(Array(selectedQuestionIds))
                    }) {
                        HStack(spacing: 8) {
                            Text("game.setup.start".localized)
                            Image(systemName: "play.fill")
                        }
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    canConfirm ?
                                    LinearGradient(
                                        colors: [Color.green, Color.teal],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(
                            color: canConfirm ? Color.green.opacity(0.5) : Color.clear,
                            radius: 20,
                            y: 10
                        )
                    }
                    .disabled(!canConfirm)

                    // Back button
                    Button(action: onBack) {
                        Text("button.back".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white.opacity(0.1))
                            )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .background(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.3).opacity(0),
                            Color(red: 0.1, green: 0.15, blue: 0.3)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)
                    .allowsHitTesting(false)
                )
            }
        }
    }

    private func toggleQuestion(_ id: String) {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()

        if selectedQuestionIds.contains(id) {
            selectedQuestionIds.remove(id)
        } else if selectedQuestionIds.count < requiredCount {
            selectedQuestionIds.insert(id)
        }
    }
}

// MARK: - Question Select Card

struct QuestionSelectCard: View {
    let question: PackQuestion
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                // Selection indicator - sized for 44pt touch target
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.cyan : Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 20, height: 20)

                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 44, height: 44) // Ensure 44pt touch target
                .contentShape(Rectangle())

                // Question text
                VStack(alignment: .leading, spacing: 8) {
                    Text(question.localizedText)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isDisabled ? .white.opacity(0.4) : .white)
                        .multilineTextAlignment(.leading)
                        .lineLimit(4)

                    // Difficulty badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(question.difficulty.color)
                            .frame(width: 8, height: 8)

                        Text(question.difficulty.localizedName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(question.difficulty.color)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(question.difficulty.color.opacity(0.15))
                    )
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cyan.opacity(0.12) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
            )
            .opacity(isDisabled ? 0.5 : 1.0)
        }
        .disabled(isDisabled && !isSelected)
    }
}

#Preview {
    if let pack = QuestionPackManager.shared.getAllPacks().first {
        ManualQuestionSelectionView(
            pack: pack,
            requiredCount: 5,
            onConfirm: { _ in },
            onBack: { }
        )
    }
}
