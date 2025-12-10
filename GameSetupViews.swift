//
//  GameSetupViews.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import SwiftUI

// MARK: - Game Setup Flow State

enum GameSetupStep {
    case packSelection
    case questionCount
    case selectionMode
    case manualSelection
}

// MARK: - Pack Selection View

struct PackSelectionView: View {
    let packs: [QuestionPack]
    let onSelect: (QuestionPack) -> Void
    let onCancel: () -> Void

    @State private var isAnimating = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

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

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Text("🎲")
                        .font(.system(size: 60))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                    Text("game.setup.select_pack".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("game.setup.select_pack.subtitle".localized)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 40)

                // Pack Grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(packs) { pack in
                            PackCard(pack: pack) {
                                let generator = UIImpactFeedbackGenerator(style: .medium)
                                generator.impactOccurred()
                                onSelect(pack)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()

                // Cancel button
                Button(action: onCancel) {
                    Text("button.cancel".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.white.opacity(0.1))
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Pack Card

struct PackCard: View {
    let pack: QuestionPack
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Image or Emoji
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [pack.category.color.opacity(0.3), pack.category.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)

                    if let imageName = pack.imageName,
                       let _ = UIImage(named: imageName) {
                        Image(imageName)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                    } else {
                        Text(pack.emoji)
                            .font(.system(size: 50))
                    }

                    // Premium badge
                    if pack.isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Text("💎")
                                    .font(.system(size: 16))
                                    .padding(6)
                                    .background(
                                        Circle()
                                            .fill(Color.black.opacity(0.5))
                                    )
                            }
                            Spacer()
                        }
                        .padding(8)
                    }
                }

                // Pack info
                VStack(spacing: 4) {
                    Text(pack.localizedName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Text("\(pack.questionCount) " + "game.setup.questions".localized)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(pack.category.color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
        }
    }
}

// MARK: - Question Count Selector

struct QuestionCountSelector: View {
    let pack: QuestionPack
    @Binding var selectedCount: Int
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isAnimating = false

    private let countOptions = [5, 10, 15]

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

            VStack(spacing: 32) {
                // Header
                VStack(spacing: 12) {
                    Text(pack.emoji)
                        .font(.system(size: 60))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                    Text("game.setup.how_many".localized)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text(pack.localizedName)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 60)

                // Count options
                HStack(spacing: 16) {
                    ForEach(countOptions, id: \.self) { count in
                        CountOptionButton(
                            count: count,
                            isSelected: selectedCount == count,
                            isEnabled: count <= pack.questionCount
                        ) {
                            let generator = UISelectionFeedbackGenerator()
                            generator.selectionChanged()
                            selectedCount = count
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Info text
                Text("game.setup.count.info".localized)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Spacer()

                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onContinue) {
                        Text("button.continue".localized)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.cyan.opacity(0.5), radius: 20, y: 10)
                    }

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
            }
        }
        .onAppear {
            isAnimating = true
            // Default to 10 if available
            if pack.questionCount >= 10 {
                selectedCount = 10
            } else if pack.questionCount >= 5 {
                selectedCount = 5
            }
        }
    }
}

struct CountOptionButton: View {
    let count: Int
    let isSelected: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text("\(count)")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(isSelected ? .white : (isEnabled ? .white.opacity(0.7) : .white.opacity(0.3)))

                Text("game.setup.questions".localized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .white.opacity(0.9) : (isEnabled ? .white.opacity(0.5) : .white.opacity(0.2)))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cyan.opacity(0.3) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Selection Mode View

struct SelectionModeView: View {
    let pack: QuestionPack
    let questionCount: Int
    @Binding var selectionMode: QuestionSelectionMode
    @Binding var verdictMode: VerdictMode
    let onContinue: () -> Void
    let onBack: () -> Void

    @State private var isAnimating = false

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

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("⚙️")
                            .font(.system(size: 60))
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)

                        Text("game.setup.options".localized)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(pack.localizedName) • \(questionCount) " + "game.setup.questions".localized)
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 40)

                    // Question Selection Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("game.setup.question_selection".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 4)

                        ForEach(QuestionSelectionMode.allCases, id: \.self) { mode in
                            ModeOptionCard(
                                icon: mode.icon,
                                title: mode.localizedName,
                                description: mode.description,
                                isSelected: selectionMode == mode,
                                isEnabled: true
                            ) {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                selectionMode = mode
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    // Verdict Mode
                    VStack(alignment: .leading, spacing: 12) {
                        Text("game.setup.verdict_mode".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .padding(.horizontal, 4)

                        ForEach(VerdictMode.allCases, id: \.self) { mode in
                            ModeOptionCard(
                                icon: mode.icon,
                                title: mode.localizedName,
                                description: mode.description,
                                isSelected: verdictMode == mode,
                                isEnabled: mode.isAvailable,
                                comingSoon: !mode.isAvailable
                            ) {
                                guard mode.isAvailable else { return }
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                verdictMode = mode
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer(minLength: 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: onContinue) {
                            HStack(spacing: 8) {
                                Text(selectionMode == .manual ? "game.setup.choose_questions".localized : "game.setup.start".localized)
                                Image(systemName: selectionMode == .manual ? "checklist" : "play.fill")
                            }
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                            .shadow(color: Color.cyan.opacity(0.5), radius: 20, y: 10)
                        }

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
                }
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ModeOptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let isEnabled: Bool
    var comingSoon: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .cyan : (isEnabled ? .white.opacity(0.7) : .white.opacity(0.3)))
                    .frame(width: 40)

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(isEnabled ? .white : .white.opacity(0.4))

                        if comingSoon {
                            Text("game.setup.coming_soon".localized)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.2))
                                )
                        }
                    }

                    Text(description)
                        .font(.system(size: 13))
                        .foregroundColor(isEnabled ? .white.opacity(0.5) : .white.opacity(0.25))
                        .lineLimit(2)
                }

                Spacer()

                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.cyan)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Color.cyan.opacity(0.15) : Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.cyan : Color.white.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Pack Category Color Extension

extension PackCategory {
    var color: Color {
        switch self {
        case .general: return .cyan
        case .spicy: return .red
        case .relationships: return .pink
        case .secrets: return .purple
        case .party: return .orange
        }
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}
