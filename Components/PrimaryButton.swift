//
//  PrimaryButton.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import SwiftUI

// MARK: - Primary Button

/// A reusable primary action button with gradient styling
struct PrimaryButton: View {
    let title: String
    var icon: String? = nil
    var iconPosition: IconPosition = .trailing
    var style: ButtonStyle = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    enum IconPosition {
        case leading, trailing
    }

    enum ButtonStyle {
        case primary    // Cyan to Blue
        case success    // Green to Teal
        case warning    // Orange to Red
        case danger     // Red to Orange

        var gradient: LinearGradient {
            switch self {
            case .primary: return Theme.Colors.primaryGradient
            case .success: return Theme.Colors.successGradient
            case .warning: return Theme.Colors.warningGradient
            case .danger: return Theme.Colors.dangerGradient
            }
        }

        var shadowColor: Color {
            switch self {
            case .primary: return Theme.Colors.primaryStart
            case .success: return Theme.Colors.successStart
            case .warning: return Theme.Colors.warningStart
            case .danger: return Theme.Colors.dangerStart
            }
        }
    }

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.sm) {
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: Theme.FontSize.headline, weight: .bold))
                }

                Text(title)
                    .font(.system(size: Theme.FontSize.title3, weight: .bold))

                if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: Theme.FontSize.headline, weight: .bold))
                }
            }
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(isEnabled ? style.gradient : Theme.Colors.disabledGradient)
            )
            .shadow(
                color: isEnabled ? style.shadowColor.opacity(Theme.Shadow.opacity) : .clear,
                radius: Theme.Shadow.radius,
                y: Theme.Shadow.y
            )
        }
        .disabled(!isEnabled)
    }
}

// MARK: - Secondary Button

/// A secondary/ghost button with transparent background
struct SecondaryButton: View {
    let title: String
    var icon: String? = nil
    var iconPosition: PrimaryButton.IconPosition = .leading
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            action()
        }) {
            HStack(spacing: Theme.Spacing.xs) {
                if let icon = icon, iconPosition == .leading {
                    Image(systemName: icon)
                        .font(.system(size: Theme.FontSize.callout, weight: .medium))
                }

                Text(title)
                    .font(.system(size: Theme.FontSize.callout, weight: .medium))

                if let icon = icon, iconPosition == .trailing {
                    Image(systemName: icon)
                        .font(.system(size: Theme.FontSize.callout, weight: .medium))
                }
            }
            .foregroundColor(Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.vertical, 18) // Minimum 44pt touch target
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .fill(Theme.Colors.surfaceLight)
            )
        }
    }
}

// MARK: - Icon Button

/// A circular icon button
struct IconButton: View {
    let icon: String
    var size: CGFloat = 44
    var style: PrimaryButton.ButtonStyle = .primary
    let action: () -> Void

    var body: some View {
        Button(action: {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .semibold))
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(style.gradient)
                )
                .shadow(
                    color: style.shadowColor.opacity(0.3),
                    radius: 10,
                    y: 5
                )
        }
    }
}

// MARK: - Previews

#Preview("Primary Buttons") {
    ZStack {
        Theme.Colors.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 16) {
            PrimaryButton(
                title: "button.im_ready".localized,
                icon: "arrow.right",
                action: {}
            )

            PrimaryButton(
                title: "button.start".localized,
                style: .success,
                action: {}
            )

            PrimaryButton(
                title: "Hot Seat",
                style: .warning,
                action: {}
            )

            PrimaryButton(
                title: "button.delete".localized,
                icon: "trash",
                iconPosition: .leading,
                style: .danger,
                action: {}
            )

            PrimaryButton(
                title: "Disabled",
                isEnabled: false,
                action: {}
            )
        }
        .padding()
    }
}

#Preview("Secondary Buttons") {
    ZStack {
        Theme.Colors.backgroundGradient.ignoresSafeArea()

        VStack(spacing: 16) {
            SecondaryButton(
                title: "button.back".localized,
                icon: "chevron.left",
                action: {}
            )

            SecondaryButton(
                title: "button.cancel".localized,
                action: {}
            )
        }
        .padding()
    }
}

#Preview("Icon Buttons") {
    ZStack {
        Theme.Colors.backgroundGradient.ignoresSafeArea()

        HStack(spacing: 20) {
            IconButton(icon: "plus", action: {})
            IconButton(icon: "play.fill", style: .success, action: {})
            IconButton(icon: "xmark", style: .danger, action: {})
        }
    }
}
