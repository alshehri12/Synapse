//
//  BadgesAndAlerts.swift
//  Synapse Design System
//
//  Badges, tags, and alert components
//

import SwiftUI

// MARK: - Badge
struct DSBadge: View {
    let text: String
    var style: BadgeStyle = .primary
    var size: BadgeSize = .medium

    enum BadgeStyle {
        case primary, secondary, success, warning, error, info

        var backgroundColor: Color {
            switch self {
            case .primary: return Color.Brand.primary
            case .secondary: return Color.Brand.secondary
            case .success: return Color.Status.success
            case .warning: return Color.Status.warning
            case .error: return Color.Status.error
            case .info: return Color.Status.info
            }
        }

        var textColor: Color {
            .white
        }
    }

    enum BadgeSize {
        case small, medium, large

        var font: Font {
            switch self {
            case .small: return .overline
            case .medium: return .captionBold
            case .large: return .labelSmall
            }
        }

        var padding: EdgeInsets {
            switch self {
            case .small: return EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6)
            case .medium: return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
            case .large: return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
            }
        }
    }

    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(style.textColor)
            .padding(size.padding)
            .background(style.backgroundColor)
            .cornerRadiusSmall()
    }
}

// MARK: - Outlined Badge
struct DSOutlinedBadge: View {
    let text: String
    var color: Color = Color.Brand.primary
    var size: DSBadge.BadgeSize = .medium

    var body: some View {
        Text(text)
            .font(size.font)
            .foregroundColor(color)
            .padding(size.padding)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                    .stroke(color, lineWidth: Spacing.borderThin)
            )
    }
}

// MARK: - Notification Badge (number)
struct DSNotificationBadge: View {
    let count: Int
    var maxCount: Int = 99

    var body: some View {
        Text(count > maxCount ? "\(maxCount)+" : "\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .frame(minWidth: 18, minHeight: 18)
            .padding(.horizontal, 4)
            .background(Color.Status.error)
            .clipShape(Capsule())
    }
}

// MARK: - Alert Banner
struct DSAlertBanner: View {
    let message: String
    var style: AlertStyle = .info
    var icon: String? = nil
    var dismissAction: (() -> Void)? = nil

    enum AlertStyle {
        case success, warning, error, info

        var backgroundColor: Color {
            switch self {
            case .success: return Color.Status.successBackground
            case .warning: return Color.Status.warningBackground
            case .error: return Color.Status.errorBackground
            case .info: return Color.Status.infoBackground
            }
        }

        var iconColor: Color {
            switch self {
            case .success: return Color.Status.success
            case .warning: return Color.Status.warning
            case .error: return Color.Status.error
            case .info: return Color.Status.info
            }
        }

        var defaultIcon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon ?? style.defaultIcon)
                .foregroundColor(style.iconColor)
                .font(.system(size: Spacing.iconMedium))

            Text(message)
                .bodyMedium(color: Color.Text.primary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let dismissAction = dismissAction {
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.Text.secondary)
                        .font(.system(size: Spacing.iconSmall))
                }
            }
        }
        .paddingMD()
        .background(style.backgroundColor)
        .cornerRadiusMedium()
    }
}

// MARK: - Toast Message
struct DSToast: View {
    let message: String
    var icon: String?
    var style: ToastStyle = .neutral

    enum ToastStyle {
        case success, error, neutral

        var backgroundColor: Color {
            switch self {
            case .success: return Color.Status.success
            case .error: return Color.Status.error
            case .neutral: return Color.Background.elevated
            }
        }

        var textColor: Color {
            switch self {
            case .success, .error: return .white
            case .neutral: return Color.Text.primary
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(style.textColor)
                    .font(.system(size: Spacing.iconMedium))
            }

            Text(message)
                .bodyMedium(color: style.textColor)
        }
        .paddingMD()
        .paddingLG()
        .background(style.backgroundColor)
        .cornerRadiusLarge()
        .shadowMD()
    }
}

// MARK: - Status Indicator
struct DSStatusIndicator: View {
    let status: Status
    var showLabel: Bool = false

    enum Status {
        case active, inactive, pending, error

        var color: Color {
            switch self {
            case .active: return Color.Status.success
            case .inactive: return Color.Text.tertiary
            case .pending: return Color.Status.warning
            case .error: return Color.Status.error
            }
        }

        var label: String {
            switch self {
            case .active: return "Active"
            case .inactive: return "Inactive"
            case .pending: return "Pending"
            case .error: return "Error"
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)

            if showLabel {
                Text(status.label)
                    .caption(color: Color.Text.secondary)
            }
        }
    }
}

// MARK: - Tag (Chip)
struct DSTag: View {
    let text: String
    var color: Color = Color.Brand.primary
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(text)
                .labelSmall(color: color)

            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(color.opacity(0.7))
                }
            }
        }
        .paddingSM()
        .background(color.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: Spacing.cornerRadiusSmall)
                .stroke(color.opacity(0.3), lineWidth: Spacing.borderThin)
        )
        .cornerRadiusSmall()
    }
}

// MARK: - Progress Indicator
struct DSProgressBar: View {
    let progress: Double // 0.0 to 1.0
    var height: CGFloat = 8
    var color: Color = Color.Brand.primary
    var backgroundColor: Color = Color.Background.tertiary

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(backgroundColor)
                    .frame(height: height)

                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1), height: height)
            }
        }
        .frame(height: height)
    }
}

// MARK: - View Modifiers for Badges
extension View {
    /// Adds a notification badge to the view
    func notificationBadge(_ count: Int) -> some View {
        self.overlay(
            DSNotificationBadge(count: count)
                .offset(x: 10, y: -10),
            alignment: .topTrailing
        )
    }

    /// Adds a status indicator to the view
    func statusIndicator(_ status: DSStatusIndicator.Status) -> some View {
        self.overlay(
            DSStatusIndicator(status: status)
                .offset(x: -4, y: -4),
            alignment: .topTrailing
        )
    }
}
