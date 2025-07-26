//
//  PodDetailView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct PodDetailView: View {
    let pod: IncubationPod
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var selectedTab = 0
    @State private var showingTaskSheet = false
    @State private var showingMemberSheet = false
    @State private var showingChat = false
    @State private var showingSettings = false
    @State private var showingAnalytics = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    // Pod Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pod.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text(pod.description)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                        
                        HStack {
                            PodStatusBadge(status: pod.status)
                            
                            Spacer()
                            
                            Text("Created \(pod.createdAt.timeAgoDisplay())")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    
                    // Quick Stats
                    HStack(spacing: 20) {
                        StatCard(
                            title: "Members".localized,
                            value: "\(pod.members.count)",
                            icon: "person.3",
                            color: Color.accentGreen
                        )
                        
                        StatCard(
                            title: "Tasks".localized,
                            value: "\(pod.tasks.count)",
                            icon: "checklist",
                            color: Color.accentBlue
                        )
                        
                        StatCard(
                            title: "Completed".localized,
                            value: "\(completedTasksCount)",
                            icon: "checkmark.circle",
                            color: Color.success
                        )
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                
                // Tab Selector
                HStack(spacing: 0) {
                    TabButton(
                        title: "Overview".localized,
                        isSelected: selectedTab == 0,
                        action: { selectedTab = 0 }
                    )
                    
                    TabButton(
                        title: "Tasks".localized,
                        isSelected: selectedTab == 1,
                        action: { selectedTab = 1 }
                    )
                    
                    TabButton(
                        title: "Members".localized,
                        isSelected: selectedTab == 2,
                        action: { selectedTab = 2 }
                    )
                    
                    TabButton(
                        title: "Chat".localized,
                        isSelected: selectedTab == 3,
                        action: { selectedTab = 3 }
                    )
                }
                .background(Color.backgroundPrimary)
                .padding(.horizontal, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OverviewTab(pod: pod)
                        .tag(0)
                    
                    TasksTab(pod: pod, showingTaskSheet: $showingTaskSheet)
                        .tag(1)
                    
                    MembersTab(pod: pod, showingMemberSheet: $showingMemberSheet)
                        .tag(2)
                    
                    ChatTab(pod: pod)
                        .tag(3)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color.backgroundSecondary)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingTaskSheet = true }) {
                            Label("Add Task".localized, systemImage: "plus.circle")
                        }
                        
                        Button(action: { showingMemberSheet = true }) {
                            Label("Invite Member".localized, systemImage: "person.badge.plus")
                        }
                        
                        Button(action: { showingChat = true }) {
                            Label("Open Chat".localized, systemImage: "message")
                        }
                        
                        Button(action: { showingAnalytics = true }) {
                            Label("Analytics".localized, systemImage: "chart.bar")
                        }
                        
                        Divider()
                        
                        Button(action: { showingSettings = true }) {
                            Label("Pod Settings".localized, systemImage: "gear")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .sheet(isPresented: $showingTaskSheet) {
                CreateTaskView(pod: pod)
            }
            .sheet(isPresented: $showingMemberSheet) {
                InviteMemberView(pod: pod)
            }
            .sheet(isPresented: $showingChat) {
                PodChatView(pod: pod)
            }
            .sheet(isPresented: $showingSettings) {
                PodSettingsView(pod: pod)
            }
            .sheet(isPresented: $showingAnalytics) {
                PodAnalyticsView(pod: pod)
            }
        }
    }
    
    private var completedTasksCount: Int {
        pod.tasks.filter { $0.status == .completed }.count
    }
}

// MARK: - Overview Tab
struct OverviewTab: View {
    let pod: IncubationPod
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Progress Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Progress".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    VStack(spacing: 16) {
                        // Overall Progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overall Progress".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                
                                Spacer()
                                
                                Text("\(Int(overallProgress * 100))%")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color.accentGreen)
                            }
                            
                            ProgressView(value: overallProgress)
                                .progressViewStyle(LinearProgressViewStyle(tint: Color.accentGreen))
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                        }
                        
                        // Task Status Breakdown
                        HStack(spacing: 20) {
                            TaskStatusCard(
                                status: "To Do".localized,
                                count: todoCount,
                                color: Color.textSecondary
                            )
                            
                            TaskStatusCard(
                                status: "In Progress".localized,
                                count: inProgressCount,
                                color: Color.accentOrange
                            )
                            
                            TaskStatusCard(
                                status: "Completed".localized,
                                count: completedCount,
                                color: Color.success
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Recent Activity
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity".localized)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 20)
                    
                    if recentActivities.isEmpty {
                        Text("No recent activity".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(recentActivities, id: \.id) { activity in
                                ActivityRow(activity: activity)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 20)
        }
    }
    
    private var overallProgress: Double {
        guard !pod.tasks.isEmpty else { return 0 }
        return Double(completedCount) / Double(pod.tasks.count)
    }
    
    private var todoCount: Int {
        pod.tasks.filter { $0.status == .todo }.count
    }
    
    private var inProgressCount: Int {
        pod.tasks.filter { $0.status == .inProgress }.count
    }
    
    private var completedCount: Int {
        pod.tasks.filter { $0.status == .completed }.count
    }
    
    private var recentActivities: [ActivityItem] {
        // TODO: Implement real activity tracking
        return []
    }
}

// MARK: - Tasks Tab
struct TasksTab: View {
    let pod: IncubationPod
    @Binding var showingTaskSheet: Bool
    @State private var selectedFilter: PodTask.TaskStatus? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    FilterButton(
                        title: "All".localized,
                        isSelected: selectedFilter == nil,
                        action: { selectedFilter = nil }
                    )
                    
                    ForEach(PodTask.TaskStatus.allCases, id: \.self) { status in
                        FilterButton(
                            title: status.rawValue.localized.capitalized,
                            isSelected: selectedFilter == status,
                            action: { selectedFilter = status }
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.vertical, 16)
            
            // Tasks List
            if filteredTasks.isEmpty {
                EmptyStateView(
                    icon: "checklist",
                    title: "No tasks".localized,
                    message: selectedFilter == nil ? "Create your first task to get started".localized : "No tasks in this status".localized
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTasks) { task in
                            TaskRow(task: task)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                }
            }
        }
        .background(Color.backgroundSecondary)
    }
    
    private var filteredTasks: [PodTask] {
        guard let filter = selectedFilter else { return pod.tasks }
        return pod.tasks.filter { $0.status == filter }
    }
}

// MARK: - Members Tab
struct MembersTab: View {
    let pod: IncubationPod
    @Binding var showingMemberSheet: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(pod.members) { member in
                    MemberRow(member: member)
                        .padding(.horizontal, 20)
                }
            }
            .padding(.vertical, 16)
        }
        .background(Color.backgroundSecondary)
    }
}

// MARK: - Chat Tab
struct ChatTab: View {
    let pod: IncubationPod
    
    var body: some View {
        PodChatView(pod: pod)
    }
}

// MARK: - Supporting Views
struct TaskStatusCard: View {
    let status: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text("\(count)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(color)
            
            Text(status)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? Color.white : Color.textSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentGreen : Color.backgroundPrimary)
                .cornerRadius(20)
        }
    }
}

struct TaskRow: View {
    let task: PodTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    if let description = task.description {
                        Text(description)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    PriorityBadge(priority: task.priority)
                    TaskStatusBadge(status: task.status)
                }
            }
            
            HStack {
                if let assignedTo = task.assignedToUsername {
                    HStack(spacing: 4) {
                        Image(systemName: "person")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                        
                        Text(assignedTo)
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                
                Spacer()
                
                if let dueDate = task.dueDate {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                        
                        Text(dueDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

struct MemberRow: View {
    let member: PodMember
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(String(member.username.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                )
            
            // Member Info
            VStack(alignment: .leading, spacing: 4) {
                Text(member.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                
                Text(member.role)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            // Role Badge
            Text(member.permissions.contains(.admin) ? "Admin".localized : "Member".localized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(member.permissions.contains(.admin) ? Color.accentGreen : Color.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(member.permissions.contains(.admin) ? Color.accentGreen.opacity(0.1) : Color.backgroundSecondary)
                .cornerRadius(8)
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

struct PriorityBadge: View {
    let priority: PodTask.TaskPriority
    
    var priorityColor: Color {
        switch priority {
        case .low: return Color.textSecondary
        case .medium: return Color.accentOrange
        case .high: return Color.accentBlue
        case .urgent: return Color.error
        }
    }
    
    var body: some View {
        Text(priority.rawValue.localized.capitalized)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(priorityColor)
            .cornerRadius(6)
    }
}

struct TaskStatusBadge: View {
    let status: PodTask.TaskStatus
    
    var statusColor: Color {
        switch status {
        case .todo: return Color.textSecondary
        case .inProgress: return Color.accentOrange
        case .completed: return Color.success
        case .cancelled: return Color.error
        }
    }
    
    var body: some View {
        Text(status.rawValue.localized.capitalized)
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(statusColor)
            .cornerRadius(6)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: ActivityItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            Circle()
                .fill(Color.accentGreen.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay(
                    Image(systemName: activityIcon)
                        .font(.system(size: 14))
                        .foregroundColor(Color.accentGreen)
                )
            
            // Activity Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.message)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textPrimary)
                
                HStack(spacing: 8) {
                    Text(activity.user)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                    
                    Text(activity.timestamp.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
    
    private var activityIcon: String {
        switch activity.type {
        case "task_created": return "plus.circle"
        case "task_completed": return "checkmark.circle"
        case "member_joined": return "person.badge.plus"
        case "message": return "message"
        default: return "circle"
        }
    }
}

// MARK: - Activity Item
struct ActivityItem: Identifiable {
    let id = UUID()
    let type: String
    let message: String
    let timestamp: Date
    let user: String
}

#Preview {
    PodDetailView(pod: mockPods[0])
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 