//
//  Theme.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 10/12/2025.
//

import SwiftUI

// MARK: - App Theme

/// Centralized theme system for consistent styling across the app
enum Theme {

    // MARK: - Colors

    enum Colors {
        // Primary gradient background
        static let backgroundGradientStart = Color(red: 0.05, green: 0.1, blue: 0.2)
        static let backgroundGradientEnd = Color(red: 0.1, green: 0.15, blue: 0.3)

        static var backgroundGradient: LinearGradient {
            LinearGradient(
                colors: [backgroundGradientStart, backgroundGradientEnd],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Primary action colors
        static let primaryStart = Color.cyan
        static let primaryEnd = Color.blue

        static var primaryGradient: LinearGradient {
            LinearGradient(
                colors: [primaryStart, primaryEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Success colors
        static let successStart = Color.green
        static let successEnd = Color.teal

        static var successGradient: LinearGradient {
            LinearGradient(
                colors: [successStart, successEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Warning/Hot Seat colors
        static let warningStart = Color.orange
        static let warningEnd = Color.red

        static var warningGradient: LinearGradient {
            LinearGradient(
                colors: [warningStart, warningEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Danger colors
        static let dangerStart = Color.red
        static let dangerEnd = Color.orange

        static var dangerGradient: LinearGradient {
            LinearGradient(
                colors: [dangerStart, dangerEnd],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Disabled state
        static let disabled = Color.gray.opacity(0.3)

        static var disabledGradient: LinearGradient {
            LinearGradient(
                colors: [disabled, disabled],
                startPoint: .leading,
                endPoint: .trailing
            )
        }

        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.75)
        static let textTertiary = Color.white.opacity(0.6)
        static let textMuted = Color.white.opacity(0.5)

        // Surface colors
        static let surfaceLight = Color.white.opacity(0.1)
        static let surfaceLighter = Color.white.opacity(0.2)
        static let surfaceStroke = Color.white.opacity(0.2)
        static let surfaceStrokeLight = Color.white.opacity(0.1)

        // Calibration status
        static let calibrated = Color.green
        static let notCalibrated = Color.orange
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 20
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
        static let xxxl: CGFloat = 40
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 20
        static let pill: CGFloat = 100
    }

    // MARK: - Font Sizes

    enum FontSize {
        static let caption: CGFloat = 11
        static let footnote: CGFloat = 12
        static let subheadline: CGFloat = 14
        static let body: CGFloat = 16
        static let callout: CGFloat = 17
        static let headline: CGFloat = 18
        static let title3: CGFloat = 20
        static let title2: CGFloat = 22
        static let title1: CGFloat = 24
        static let largeTitle: CGFloat = 28
        static let display: CGFloat = 32
        static let hero: CGFloat = 36
    }

    // MARK: - Animation Durations

    enum Animation {
        static let fast: Double = 0.15
        static let normal: Double = 0.3
        static let slow: Double = 0.5
        static let verySlow: Double = 0.8

        static let springResponse: Double = 0.6
        static let springDamping: Double = 0.7
    }

    // MARK: - Shadow

    enum Shadow {
        static let radius: CGFloat = 20
        static let y: CGFloat = 10
        static let opacity: Double = 0.5
    }

    // MARK: - Touch Targets

    enum TouchTarget {
        static let minimum: CGFloat = 44
        static let comfortable: CGFloat = 48
    }

    // MARK: - Timeouts

    enum Timeout {
        static let speechRecognition: TimeInterval = 10.0
        static let countdown: Int = 3
    }
}

// MARK: - View Extensions

extension View {
    /// Apply the standard app background gradient
    func appBackground() -> some View {
        self.background(Theme.Colors.backgroundGradient.ignoresSafeArea())
    }

    /// Apply primary button styling
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        self
            .font(.system(size: Theme.FontSize.title3, weight: .bold))
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(isEnabled ? Theme.Colors.primaryGradient : Theme.Colors.disabledGradient)
            )
            .shadow(
                color: isEnabled ? Theme.Colors.primaryStart.opacity(Theme.Shadow.opacity) : .clear,
                radius: Theme.Shadow.radius,
                y: Theme.Shadow.y
            )
    }

    /// Apply success button styling
    func successButtonStyle() -> some View {
        self
            .font(.system(size: Theme.FontSize.title3, weight: .bold))
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.Colors.successGradient)
            )
            .shadow(
                color: Theme.Colors.successStart.opacity(Theme.Shadow.opacity),
                radius: Theme.Shadow.radius,
                y: Theme.Shadow.y
            )
    }

    /// Apply warning/hot seat button styling
    func warningButtonStyle() -> some View {
        self
            .font(.system(size: Theme.FontSize.title3, weight: .bold))
            .foregroundColor(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .fill(Theme.Colors.warningGradient)
            )
            .shadow(
                color: Theme.Colors.warningStart.opacity(Theme.Shadow.opacity),
                radius: Theme.Shadow.radius,
                y: Theme.Shadow.y
            )
    }

    /// Apply card styling
    func cardStyle() -> some View {
        self
            .padding(Theme.Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xlarge)
                    .fill(Theme.Colors.surfaceLight)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.xlarge)
                    .stroke(Theme.Colors.surfaceStroke, lineWidth: 1)
            )
    }
}

// MARK: - Gradient Helpers

extension LinearGradient {
    /// Create a gradient for player calibration status
    static func calibrationStatus(isCalibrated: Bool) -> LinearGradient {
        LinearGradient(
            colors: isCalibrated ?
                [Theme.Colors.successStart, Theme.Colors.successEnd] :
                [Theme.Colors.warningStart, Theme.Colors.warningEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
