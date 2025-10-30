//
//  LoadingStates.swift
//  Synapse Design System
//
//  Loading indicators and skeleton screens
//

import SwiftUI

// MARK: - Loading Spinner
struct DSLoadingSpinner: View {
    var size: CGFloat = Spacing.iconLarge
    var color: Color = Color.Brand.primary

    var body: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: color))
            .scaleEffect(size / Spacing.iconLarge)
    }
}

// MARK: - Loading Overlay
struct DSLoadingOverlay: View {
    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        ZStack {
            Color.Background.overlay
                .ignoresSafeArea()

            VStack(spacing: Spacing.lg) {
                DSLoadingSpinner(size: Spacing.iconExtraLarge, color: .white)

                if let message = message {
                    Text(message)
                        .bodyMedium(color: .white)
                }
            }
            .paddingXL2()
            .background(Color.Background.elevated)
            .cornerRadiusLarge()
            .shadowXL()
        }
    }
}

// MARK: - Skeleton Loading Views
struct SkeletonView: View {
    var width: CGFloat?
    var height: CGFloat
    var cornerRadius: CGFloat = Spacing.cornerRadiusSmall

    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.Background.tertiary,
                        Color.Background.secondary,
                        Color.Background.tertiary
                    ],
                    startPoint: isAnimating ? .leading : .trailing,
                    endPoint: isAnimating ? .trailing : .leading
                )
            )
            .frame(width: width, height: height)
            .cornerRadius(cornerRadius)
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5).repeatForever(autoreverses: false)
                ) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton Card
struct SkeletonCard: View {
    var includeImage: Bool = true
    var lines: Int = 3

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if includeImage {
                SkeletonView(height: 150, cornerRadius: Spacing.cornerRadiusMedium)
            }

            SkeletonView(width: 200, height: 20)

            ForEach(0..<lines, id: \.self) { index in
                SkeletonView(
                    width: index == lines - 1 ? 150 : nil,
                    height: 14
                )
            }
        }
        .cardPadding()
        .background(Color.Background.elevated)
        .cornerRadiusMedium()
        .cardShadow()
    }
}

// MARK: - Skeleton List Item
struct SkeletonListItem: View {
    var hasAvatar: Bool = true

    var body: some View {
        HStack(spacing: Spacing.md) {
            if hasAvatar {
                SkeletonView(
                    width: Spacing.avatarMedium,
                    height: Spacing.avatarMedium,
                    cornerRadius: Spacing.avatarMedium / 2
                )
            }

            VStack(alignment: .leading, spacing: Spacing.sm) {
                SkeletonView(width: 150, height: 16)
                SkeletonView(width: 100, height: 12)
            }

            Spacer()
        }
        .paddingMD()
    }
}

// MARK: - Empty State View
struct DSEmptyState: View {
    let icon: String
    let title: String
    let subtitle: String?
    var action: (() -> Void)? = nil
    var actionTitle: String? = nil

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: Spacing.xl) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(Color.Text.tertiary)

            VStack(spacing: Spacing.sm) {
                Text(title)
                    .heading5()

                if let subtitle = subtitle {
                    Text(subtitle)
                        .bodyMedium(color: Color.Text.secondary)
                        .multilineTextAlignment(.center)
                }
            }

            if let action = action, let actionTitle = actionTitle {
                PrimaryButton(title: actionTitle, action: action)
                    .frame(maxWidth: 200)
            }
        }
        .paddingXL3()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading State Modifier
extension View {
    /// Shows a loading overlay when isLoading is true
    func loadingOverlay(isLoading: Bool, message: String? = nil) -> some View {
        ZStack {
            self

            if isLoading {
                DSLoadingOverlay(message: message)
            }
        }
    }
}
