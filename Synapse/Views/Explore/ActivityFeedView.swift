//
//  ActivityFeedView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct ActivityFeedView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    @State private var activities: [FeedActivityItem] = []
    @State private var isLoading = false
    @State private var selectedFilter: ActivityFilter = .all
    
    enum ActivityFilter: String, CaseIterable {
        case all = "All"
        case ideas = "Ideas"
        case pods = "Pods"
        case tasks = "Tasks"
        case social = "Social"
    }
    
    var filteredActivities: [FeedActivityItem] {
        let filtered = activities.filter { activity in
            switch selectedFilter {
            case .all:
                return true
            case .ideas:
                return activity.type == .ideaCreated || activity.type == .ideaLiked || activity.type == .ideaCommented
            case .pods:
                return activity.type == .podCreated || activity.type == .podJoined || activity.type == .podCompleted
            case .tasks:
                return activity.type == .taskCreated || activity.type == .taskCompleted
            case .social:
                return activity.type == .userJoined || activity.type == .userFollowed
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
                        ForEach(ActivityFilter.allCases, id: \.self) { filter in
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
                
                // Activity Feed
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredActivities.isEmpty {
                    EmptyStateView(
                        icon: "clock",
                        title: "No activity yet".localized,
                        message: "Be the first to spark some activity!".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredActivities) { activity in
                                FeedActivityRow(activity: activity)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Activity Feed".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadActivities()
            }
            .refreshable {
                await refreshActivities()
            }
        }
    }
    
    private func loadActivities() {
        isLoading = true
        // TODO: Load activities from Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            activities = mockActivities
            isLoading = false
        }
    }
    
    private func refreshActivities() async {
        // TODO: Refresh activities from Firebase
        await Task.sleep(1_000_000_000) // 1 second
        loadActivities()
    }
}

// MARK: - Activity Row
struct FeedActivityRow: View {
    let activity: FeedActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // User Avatar
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(activity.userName.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Activity Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(activity.userName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text(activity.message)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                }
                
                Text(activity.timestamp.timeAgoDisplay())
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            // Activity Icon
            Image(systemName: activityIcon)
                .font(.system(size: 16))
                .foregroundColor(activityColor)
                .frame(width: 32, height: 32)
                .background(activityColor.opacity(0.1))
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case .ideaCreated:
            return "lightbulb"
        case .ideaLiked:
            return "heart"
        case .ideaCommented:
            return "message"
        case .podCreated:
            return "person.3"
        case .podJoined:
            return "person.badge.plus"
        case .podCompleted:
            return "checkmark.circle"
        case .taskCreated:
            return "checklist"
        case .taskCompleted:
            return "checkmark.circle.fill"
        case .userJoined:
            return "person.crop.circle.badge.plus"
        case .userFollowed:
            return "person.2"
        }
    }
    
    private var activityColor: Color {
        switch activity.type {
        case .ideaCreated, .ideaLiked, .ideaCommented:
            return Color.accentOrange
        case .podCreated, .podJoined, .podCompleted:
            return Color.accentGreen
        case .taskCreated, .taskCompleted:
            return Color.accentBlue
        case .userJoined, .userFollowed:
            return Color.accentGreen
        }
    }
}

// MARK: - Activity Item Model
struct FeedActivityItem: Identifiable, Codable {
    let id: String
    let userId: String
    let userName: String
    let type: ActivityType
    let message: String
    let relatedId: String?
    let timestamp: Date
    
    enum ActivityType: String, Codable, CaseIterable {
        case ideaCreated = "idea_created"
        case ideaLiked = "idea_liked"
        case ideaCommented = "idea_commented"
        case podCreated = "pod_created"
        case podJoined = "pod_joined"
        case podCompleted = "pod_completed"
        case taskCreated = "task_created"
        case taskCompleted = "task_completed"
        case userJoined = "user_joined"
        case userFollowed = "user_followed"
    }
}

// MARK: - Mock Activities
let mockActivities: [FeedActivityItem] = [
    FeedActivityItem(
        id: "1",
        userId: "user1",
        userName: "AlexChen",
        type: .ideaCreated,
        message: "created a new idea",
        relatedId: "idea1",
        timestamp: Date().addingTimeInterval(-1800)
    ),
    FeedActivityItem(
        id: "2",
        userId: "user2",
        userName: "SarahKim",
        type: .podJoined,
        message: "joined the AI Study Assistant pod",
        relatedId: "pod1",
        timestamp: Date().addingTimeInterval(-3600)
    ),
    FeedActivityItem(
        id: "3",
        userId: "user3",
        userName: "MariaGarcia",
        type: .ideaLiked,
        message: "liked your idea",
        relatedId: "idea2",
        timestamp: Date().addingTimeInterval(-5400)
    ),
    FeedActivityItem(
        id: "4",
        userId: "user4",
        userName: "JohnSmith",
        type: .taskCompleted,
        message: "completed a task in Sustainable Food Network",
        relatedId: "task1",
        timestamp: Date().addingTimeInterval(-7200)
    ),
    FeedActivityItem(
        id: "5",
        userId: "user5",
        userName: "EmmaWilson",
        type: .podCreated,
        message: "created a new pod",
        relatedId: "pod2",
        timestamp: Date().addingTimeInterval(-9000)
    ),
    FeedActivityItem(
        id: "6",
        userId: "user6",
        userName: "DavidBrown",
        type: .userJoined,
        message: "joined Synapse",
        relatedId: nil,
        timestamp: Date().addingTimeInterval(-10800)
    ),
    FeedActivityItem(
        id: "7",
        userId: "user7",
        userName: "LisaChen",
        type: .ideaCommented,
        message: "commented on your idea",
        relatedId: "idea3",
        timestamp: Date().addingTimeInterval(-12600)
    ),
    FeedActivityItem(
        id: "8",
        userId: "user8",
        userName: "MikeJohnson",
        type: .taskCreated,
        message: "created a new task",
        relatedId: "task2",
        timestamp: Date().addingTimeInterval(-14400)
    )
] 