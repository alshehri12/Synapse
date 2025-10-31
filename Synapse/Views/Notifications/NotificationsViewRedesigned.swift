//
//  NotificationsViewRedesigned.swift
//  Synapse
//
//  Elegant redesigned notifications page
//

import SwiftUI
import Supabase

struct NotificationsViewRedesigned: View {
    @State private var selectedFilter: NotificationFilter = .all
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager

    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case mentions = "Mentions"
        case tasks = "Tasks"

        var icon: String {
            switch self {
            case .all: return "tray.fill"
            case .unread: return "circle.fill"
            case .mentions: return "at"
            case .tasks: return "checklist"
            }
        }
    }

    var filteredNotifications: [AppNotification] {
        let filtered = notifications.filter { notification in
            switch selectedFilter {
            case .all:
                return true
            case .unread:
                return !notification.isRead
            case .mentions:
                return notification.type == .mention
            case .tasks:
                return notification.type == .taskAssigned || notification.type == .taskCompleted
            }
        }
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Custom elegant header
                NotificationsHeader(
                    unreadCount: unreadCount,
                    onMarkAllRead: markAllAsRead
                )
                .environmentObject(localizationManager)

                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.md) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterChipElegant(
                                title: filter.rawValue.localized,
                                icon: filter.icon,
                                isSelected: selectedFilter == filter,
                                count: getFilterCount(filter)
                            ) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.md)
                .background(Color.Background.primary)

                Divider()
                    .background(Color.Border.primary)

                // Content
                if isLoading {
                    loadingView
                } else if filteredNotifications.isEmpty {
                    emptyStateView
                } else {
                    notificationsList
                }
            }
            .background(Color.Background.secondary)
            .navigationBarHidden(true)
            .onAppear {
                loadNotifications()
            }
            .refreshable {
                await refreshNotifications()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Spacing.xl) {
            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.Brand.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.Brand.primary, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                    .rotateForever(duration: 1.0)
            }

            Text("Loading notifications...".localized)
                .bodyMedium(color: Color.Text.secondary)

            Spacer()
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: Spacing.xl2) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.Brand.primaryLight)
                    .frame(width: 100, height: 100)

                Image(systemName: getEmptyIcon())
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Color.Brand.primary)
            }

            VStack(spacing: Spacing.sm) {
                Text(getEmptyTitle())
                    .heading4()
                    .multilineTextAlignment(.center)

                Text(getEmptyMessage())
                    .bodyMedium(color: Color.Text.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl3)
            }

            Spacer()
        }
        .padding()
    }

    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(filteredNotifications) { notification in
                    ElegantNotificationRow(
                        notification: notification,
                        onAction: { handleNotificationAction(notification) }
                    )
                    .environmentObject(supabaseManager)
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
        }
    }

    // MARK: - Helper Methods

    private func getFilterCount(_ filter: NotificationFilter) -> Int? {
        switch filter {
        case .all:
            return nil
        case .unread:
            let count = notifications.filter { !$0.isRead }.count
            return count > 0 ? count : nil
        case .mentions:
            let count = notifications.filter { $0.type == .mention }.count
            return count > 0 ? count : nil
        case .tasks:
            let count = notifications.filter { $0.type == .taskAssigned || $0.type == .taskCompleted }.count
            return count > 0 ? count : nil
        }
    }

    private func getEmptyIcon() -> String {
        switch selectedFilter {
        case .all: return "tray"
        case .unread: return "checkmark.circle"
        case .mentions: return "at.circle"
        case .tasks: return "checklist.checked"
        }
    }

    private func getEmptyTitle() -> String {
        switch selectedFilter {
        case .all: return "No Notifications".localized
        case .unread: return "All Caught Up!".localized
        case .mentions: return "No Mentions".localized
        case .tasks: return "No Task Updates".localized
        }
    }

    private func getEmptyMessage() -> String {
        switch selectedFilter {
        case .all: return "You don't have any notifications yet".localized
        case .unread: return "You've read all your notifications".localized
        case .mentions: return "No one has mentioned you recently".localized
        case .tasks: return "You don't have any task notifications".localized
        }
    }

    private func loadNotifications() {
        guard let currentUser = supabaseManager.currentUser else { return }

        isLoading = true

        Task {
            do {
                let notificationData = try await supabaseManager.getUserNotifications(userId: currentUser.uid)

                await MainActor.run {
                    notifications = notificationData
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }

    private func refreshNotifications() async {
        loadNotifications()
    }

    private func markAllAsRead() {
        guard let currentUser = supabaseManager.currentUser else { return }

        HapticFeedback.success()

        Task {
            do {
                try await supabaseManager.markAllNotificationsAsRead(userId: currentUser.uid)

                await MainActor.run {
                    for index in notifications.indices {
                        notifications[index].isRead = true
                    }
                }
            } catch {
                print("❌ Error marking notifications as read: \(error.localizedDescription)")
            }
        }
    }

    private func handleNotificationAction(_ notification: AppNotification) {
        // Mark as read when tapped
        if !notification.isRead {
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = true
            }
        }
    }
}

// MARK: - Elegant Filter Chip
struct FilterChipElegant: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))

                Text(title)
                    .font(.system(size: 14, weight: .semibold))

                if let count = count {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : Color.Brand.primary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            isSelected ? Color.Brand.primary.opacity(0.3) : Color.Brand.primaryLight
                        )
                        .cornerRadiusRound()
                }
            }
            .foregroundColor(isSelected ? .white : Color.Text.primary)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Group {
                    if isSelected {
                        LinearGradient(
                            colors: [Color.Brand.primary, Color.Brand.primaryDark],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    } else {
                        Color.Background.elevated
                    }
                }
            )
            .cornerRadiusRound()
            .shadowXS()
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Elegant Notification Row
struct ElegantNotificationRow: View {
    let notification: AppNotification
    let onAction: () -> Void
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var isProcessing = false

    var body: some View {
        Button(action: onAction) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    notificationColor.opacity(0.2),
                                    notificationColor.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)

                    Image(systemName: notificationIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(notificationColor)
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(notification.message)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.Text.primary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: Spacing.xs) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(notification.timestamp.timeAgoDisplay())
                            .font(.system(size: 13))
                    }
                    .foregroundColor(Color.Text.tertiary)

                    // Action buttons for project invites
                    if notification.type == .projectInvite {
                        HStack(spacing: Spacing.md) {
                            Button(action: { handleInvite(accepted: true) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Accept")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.Status.success)
                                .cornerRadiusSmall()
                            }

                            Button(action: { handleInvite(accepted: false) }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "xmark")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Decline")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundColor(Color.Text.primary)
                                .padding(.horizontal, Spacing.lg)
                                .padding(.vertical, Spacing.sm)
                                .background(Color.Background.secondary)
                                .cornerRadiusSmall()
                            }
                        }
                        .padding(.top, Spacing.xs)
                    }
                }

                Spacer()

                // Unread indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.Brand.primary)
                        .frame(width: 10, height: 10)
                        .padding(.top, 4)
                }
            }
            .padding(Spacing.lg)
            .background(Color.Background.elevated)
            .cornerRadiusMedium()
            .shadowSM()
            .opacity(isProcessing ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isProcessing)
    }

    private func handleInvite(accepted: Bool) {
        guard let invitation = notification.podInvitation else { return }
        isProcessing = true

        HapticFeedback.impact(style: .medium)

        Task {
            do {
                if accepted {
                    let requesterProfile = try await supabaseManager.getUserProfile(userId: invitation.inviteeId)
                    let username = requesterProfile?["username"] as? String ?? "New Member"
                    try await supabaseManager.approveJoinRequest(invitationId: invitation.id, podId: invitation.podId, userId: invitation.inviteeId, username: username)
                    HapticFeedback.success()
                } else {
                    try await supabaseManager.rejectJoinRequest(invitationId: invitation.id, userId: invitation.inviteeId)
                    HapticFeedback.impact(style: .light)
                }

                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                HapticFeedback.error()
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
    }

    private var notificationColor: Color {
        switch notification.type {
        case .projectInvite, .projectJoined:
            return Color.Brand.primary
        case .taskAssigned, .taskCompleted:
            return Color.Brand.tertiary
        case .mention:
            return Color.Brand.secondary
        case .like, .comment:
            return Color.Status.warning
        }
    }

    private var notificationIcon: String {
        switch notification.type {
        case .projectInvite:
            return "person.badge.plus.fill"
        case .projectJoined:
            return "person.3.fill"
        case .taskAssigned:
            return "checklist"
        case .taskCompleted:
            return "checkmark.circle.fill"
        case .mention:
            return "at"
        case .like:
            return "heart.fill"
        case .comment:
            return "message.fill"
        }
    }
}

#Preview {
    NotificationsViewRedesigned()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
}
