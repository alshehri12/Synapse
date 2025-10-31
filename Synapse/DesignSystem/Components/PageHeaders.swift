//
//  PageHeaders.swift
//  Synapse Design System
//
//  Elegant page headers for main app screens
//

import SwiftUI

// MARK: - Explore Header
struct ExploreHeader: View {
    @Binding var searchText: String
    let onActivityTap: () -> Void
    let onCreateIdea: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Title and Actions
            HStack(spacing: Spacing.lg) {
                // Title with Icon
                HStack(spacing: Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.Brand.primary.opacity(0.2),
                                        Color.Brand.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color.Brand.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Explore".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.Text.primary)

                        Text("Discover amazing ideas".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.Text.secondary)
                    }
                }

                Spacer()

                // Action Buttons
                HStack(spacing: Spacing.sm) {
                    // Activity Button
                    Button(action: onActivityTap) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(Color.Text.primary)
                                .frame(width: 40, height: 40)
                                .background(Color.Background.secondary)
                                .cornerRadiusSmall()
                        }
                    }

                    // Create Idea Button
                    Button(action: onCreateIdea) {
                        HStack(spacing: Spacing.sm) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .bold))
                            Text("New".localized)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md)
                        .background(
                            LinearGradient(
                                colors: [Color.Brand.primary, Color.Brand.primaryDark],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadiusRound()
                        .shadowSM()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)

            // Search Bar
            HStack(spacing: Spacing.md) {
                HStack(spacing: Spacing.md) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.Text.tertiary)
                        .font(.system(size: 16))

                    TextField("Search ideas, tags, or users...".localized, text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(Color.Text.primary)
                }
                .padding(Spacing.md)
                .background(Color.Background.secondary)
                .cornerRadiusMedium()

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(Color.Text.tertiary)
                            .font(.system(size: 18))
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.lg)
        }
        .background(Color.Background.primary)
        .shadowSM()
    }
}

// MARK: - My Projects Header
struct MyProjectsHeader: View {
    let onCreateProject: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.lg) {
                // Title with Icon
                HStack(spacing: Spacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.Brand.primary.opacity(0.2),
                                        Color.Brand.primary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)

                        Image(systemName: "folder.fill.badge.person.crop")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.Brand.primary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("My Projects".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.Text.primary)

                        Text("Collaborate and build".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.Text.secondary)
                    }
                }

                Spacer()

                // Create Project Button
                Button(action: onCreateProject) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text("New".localized)
                            .font(.system(size: 14, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.md)
                    .background(
                        LinearGradient(
                            colors: [Color.Brand.primary, Color.Brand.primaryDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadiusRound()
                    .shadowSM()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.Background.primary)
        .shadowSM()
    }
}

// MARK: - Notifications Header
struct NotificationsHeader: View {
    let unreadCount: Int
    let onMarkAllRead: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.lg) {
                // Title with Icon and Badge
                HStack(spacing: Spacing.md) {
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.Brand.primary.opacity(0.2),
                                            Color.Brand.primary.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 40, height: 40)

                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(Color.Brand.primary)
                        }

                        if unreadCount > 0 {
                            Circle()
                                .fill(Color.Status.error)
                                .frame(width: 18, height: 18)
                                .overlay(
                                    Text("\(min(unreadCount, 9))")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 4, y: -4)
                        }
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Notifications".localized)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.Text.primary)

                        if unreadCount > 0 {
                            Text("\(unreadCount) unread")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.Brand.primary)
                        } else {
                            Text("You're all caught up!".localized)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.Text.secondary)
                        }
                    }
                }

                Spacer()

                // Mark All Read Button
                if unreadCount > 0 {
                    Button(action: onMarkAllRead) {
                        Text("Mark all read".localized)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Color.Brand.primary)
                            .padding(.horizontal, Spacing.md)
                            .padding(.vertical, Spacing.sm)
                            .background(Color.Brand.primaryLight)
                            .cornerRadiusSmall()
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.Background.primary)
        .shadowSM()
    }
}

// MARK: - Profile Header
struct ProfilePageHeader: View {
    let username: String
    let email: String
    let avatarInitial: String
    let onSettings: () -> Void
    @EnvironmentObject private var localizationManager: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.lg) {
                // Avatar and Info
                HStack(spacing: Spacing.md) {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.Brand.primary, Color.Brand.primaryDark],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 48, height: 48)

                        Text(avatarInitial)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .shadowSM()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(username)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color.Text.primary)

                        Text(email)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(Color.Text.secondary)
                    }
                }

                Spacer()

                // Settings Button
                Button(action: onSettings) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(Color.Text.primary)
                        .frame(width: 40, height: 40)
                        .background(Color.Background.secondary)
                        .cornerRadiusSmall()
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.lg)
        }
        .background(Color.Background.primary)
        .shadowSM()
    }
}
