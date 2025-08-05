//
//  NotificationsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore



struct NotificationsView: View {
    @State private var selectedFilter: NotificationFilter = .all
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var showingMarkAllRead = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    enum NotificationFilter: String, CaseIterable {
        case all = "All"
        case unread = "Unread"
        case mentions = "Mentions"
        case tasks = "Tasks"
        case pods = "Pods"
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
            case .pods:
                return notification.type == .projectInvite || notification.type == .projectJoined
            }
        }
        return filtered.sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(NotificationFilter.allCases, id: \.self) { filter in
                            FilterChip(
                                title: filter.rawValue.localized,
                                isSelected: selectedFilter == filter
                            ) {
                                selectedFilter = filter
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color.backgroundPrimary)
                
                // Notifications List
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredNotifications.isEmpty {
                    EmptyStateView(
                        icon: "bell.slash",
                        title: "No notifications".localized,
                        message: getEmptyMessage()
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredNotifications) { notification in
                                NotificationRow(notification: notification) {
                                    handleNotificationAction(notification)
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Notifications".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !notifications.isEmpty {
                        Button("Mark All as Read".localized) {
                            markAllAsRead()
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .onAppear {
                loadNotifications()
            }
            .refreshable {
                await refreshNotifications()
            }
        }
    }
    
    private func loadNotifications() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let notificationData = try await firebaseManager.getUserNotifications(userId: currentUser.uid)
                
                await MainActor.run {
                    notifications = notificationData.compactMap { data in
                        guard let id = data["id"] as? String,
                              let userId = data["userId"] as? String,
                              let typeString = data["type"] as? String,
                              let type = AppNotification.NotificationType(rawValue: typeString),
                              let message = data["message"] as? String,
                              let isRead = data["isRead"] as? Bool,
                              let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() else {
                            return nil
                        }
                        
                        let relatedId = data["relatedId"] as? String
                        
                        return AppNotification(
                            id: id,
                            userId: userId,
                            type: type,
                            message: message,
                            relatedId: relatedId?.isEmpty == false ? relatedId : nil,
                            isRead: isRead,
                            timestamp: timestamp
                        )
                    }
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
    
    private func getEmptyMessage() -> String {
        switch selectedFilter {
        case .all:
            return "You're all caught up!".localized
        case .unread:
            return "No unread notifications".localized
        case .mentions:
            return "No mentions notifications".localized
        case .tasks:
            return "No tasks notifications".localized
        case .pods:
            return "No pods notifications".localized
        }
    }
    
    private func markAllAsRead() {
        Task {
            do {
                for notification in notifications where !notification.isRead {
                    try await firebaseManager.markNotificationAsRead(notificationId: notification.id)
                }
                
                await MainActor.run {
                    for index in notifications.indices {
                        notifications[index].isRead = true
                    }
                }
            } catch {
                // Handle error silently for now
            }
        }
    }
    
    private func handleNotificationAction(_ notification: AppNotification) {
        // TODO: Handle notification actions (navigate to relevant screen)
        switch notification.type {
        case .projectInvite:
            // Navigate to project invite screen
            break
        case .taskAssigned:
            // Navigate to task detail
            break
        case .mention:
            // Navigate to comment/mention
            break
        default:
            break
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Notification Icon
                Circle()
                    .fill(notificationColor.opacity(0.1))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: notificationIcon)
                            .font(.system(size: 16))
                            .foregroundColor(notificationColor)
                    )
                
                // Notification Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.message)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(notification.timestamp.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Unread Indicator
                if !notification.isRead {
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(16)
            .background(Color.backgroundPrimary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .projectInvite, .projectJoined:
            return Color.accentGreen
        case .taskAssigned, .taskCompleted:
            return Color.accentBlue
        case .mention:
            return Color.accentOrange
        case .like, .comment:
            return Color.accentOrange
        }
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .projectInvite:
            return "person.badge.plus"
        case .projectJoined:
            return "person.3"
        case .taskAssigned:
            return "checklist"
        case .taskCompleted:
            return "checkmark.circle"
        case .mention:
            return "at"
        case .like:
            return "heart"
        case .comment:
            return "message"
        }
    }
}



#Preview {
    NotificationsView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 
