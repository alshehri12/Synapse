//
//  NotificationsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase



struct NotificationsView: View {
    @State private var selectedFilter: NotificationFilter = .all
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false
    @State private var showingMarkAllRead = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
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
                                NotificationRow(notification: notification, onAction: {
                                    handleNotificationAction(notification)
                                })
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
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                let notificationData = try await supabaseManager.getUserNotifications(userId: currentUser.uid)
                
                await MainActor.run {
                    // The notificationData is already parsed as [AppNotification] from SupabaseManager
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
                    // TODO: Implement markNotificationAsRead in SupabaseManager
                    print("✅ Mark notification as read requested: \(notification.id)")
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
        if notification.type == .projectInvite, let invitation = notification.podInvitation {
            // The action is handled by the buttons in NotificationRow now.
            // This could be used for navigation if needed.
            print("Tapped on project invite notification: \(invitation.id)")
        }
    }
}

// MARK: - Notification Row
struct NotificationRow: View {
    let notification: AppNotification
    let onAction: () -> Void
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    @State private var isProcessing = false
    
    var body: some View {
        Button(action: onAction) {
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
                
                // Action buttons for project invites
                if notification.type == .projectInvite {
                    HStack(spacing: 12) {
                        Button(action: { handleInvite(accepted: true) }) {
                            Text("Approve")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.accentGreen)
                                .cornerRadius(12)
                        }
                        
                        Button(action: { handleInvite(accepted: false) }) {
                            Text("Reject")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.backgroundPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.border, lineWidth: 1)
                                )
                        }
                    }
                    .padding(.top, 8)
                }
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
            .opacity(isProcessing ? 0.5 : 1.0)
            .disabled(isProcessing)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleInvite(accepted: Bool) {
        guard let invitation = notification.podInvitation else { return }
        isProcessing = true
        
        Task {
            do {
                if accepted {
                    // Fetch the inviter's profile to get their username
                    let inviterProfile = try await supabaseManager.getUserProfile(userId: invitation.inviterId)
                    let username = inviterProfile?["username"] as? String ?? "New Member"
                    
                    try await supabaseManager.approveJoinRequest(invitationId: invitation.id, podId: invitation.podId, userId: invitation.inviterId, username: username)
                    print("✅ Invitation approved: \(invitation.id) for user \(username)")
                } else {
                    try await supabaseManager.rejectJoinRequest(invitationId: invitation.id, userId: invitation.inviterId)
                    print("❌ Invitation rejected: \(invitation.id)")
                }
                
                await MainActor.run {
                    isProcessing = false
                }
            } catch {
                print("Error handling invitation: \(error.localizedDescription)")
                await MainActor.run {
                    isProcessing = false
                }
            }
        }
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
        .environmentObject(SupabaseManager.shared)
} 
