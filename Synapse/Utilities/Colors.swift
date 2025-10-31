//
//  Colors.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//
//  UPDATED: Now using adaptive colors from ColorTokens.swift for dark mode support
//

import SwiftUI

extension Color {
    // MARK: - Legacy Color Names (mapped to new Design System)
    // These maintain backwards compatibility while adding dark mode support

    // Primary Colors - now adaptive
    static let accentGreen = Brand.primary
    static let accentOrange = Brand.secondary
    static let accentBlue = Brand.tertiary

    // Text Colors - now adaptive
    static let textPrimary = Text.primary
    static let textSecondary = Text.secondary

    // Background Colors - now adaptive
    static let backgroundPrimary = Background.primary
    static let backgroundSecondary = Background.secondary

    // Border Colors - now adaptive
    static let border = Border.primary

    // Status Colors - now adaptive
    static let success = Status.success
    static let warning = Status.warning
    static let error = Status.error
    static let info = Status.info
} 