//
//  PodAnalyticsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct PodAnalyticsView: View {
    let pod: IncubationPod
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    @State private var selectedTimeRange: TimeRange = .week
    @State private var analytics: PodAnalytics?
    @State private var isLoading = false
    
    enum TimeRange: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case quarter = "Quarter"
        case year = "Year"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(pod.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(Color.textPrimary)
                        
                        Text("Analytics & Insights".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 20)
                    
                    // Time Range Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(TimeRange.allCases, id: \.self) { range in
                                FilterChip(
                                    title: range.rawValue.localized,
                                    isSelected: selectedTimeRange == range
                                ) {
                                    selectedTimeRange = range
                                    loadAnalytics()
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                                .scaleEffect(1.2)
                            Text("Loading analytics...".localized)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                                .padding(.top, 8)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if let analytics = analytics {
                        // Key Metrics
                        KeyMetricsSection(analytics: analytics)
                        
                        // Progress Charts
                        ProgressChartsSection(analytics: analytics)
                        
                        // Member Activity
                        MemberActivitySection(analytics: analytics)
                    }
                }
                .padding(.vertical, 16)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Analytics".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadAnalytics()
            }
        }
    }
    
    private func loadAnalytics() {
        isLoading = true
        
        Task {
            do {
                let analyticsData = try await firebaseManager.getPodAnalytics(podId: pod.id)
                
                await MainActor.run {
                    // Convert Firebase data to PodAnalytics model
                    let completionRate = analyticsData["completionRate"] as? Int ?? 0
                    let activeMembers = analyticsData["activeMembers"] as? Int ?? 0
                    let tasksCompleted = analyticsData["tasksCompleted"] as? Int ?? 0
                    let totalTasks = analyticsData["totalTasks"] as? Int ?? 0
                    let avgResponseTime = analyticsData["avgResponseTime"] as? Int ?? 4
                    
                    let taskProgressData = analyticsData["taskProgress"] as? [[String: Any]] ?? []
                    let taskProgress = taskProgressData.compactMap { data -> TaskProgressData? in
                        guard let date = data["date"] as? Date,
                              let value = data["value"] as? Int else { return nil }
                        return TaskProgressData(date: date, value: value)
                    }
                    
                    let memberActivityData = analyticsData["memberActivity"] as? [[String: Any]] ?? []
                    let memberActivity = memberActivityData.compactMap { data -> MemberActivityData? in
                        guard let member = data["member"] as? String,
                              let tasksCompleted = data["tasksCompleted"] as? Int else { return nil }
                        return MemberActivityData(member: member, tasksCompleted: tasksCompleted)
                    }
                    
                    let topContributorsData = analyticsData["topContributors"] as? [[String: Any]] ?? []
                    let topContributors = topContributorsData.compactMap { data -> TopContributor? in
                        guard let username = data["username"] as? String,
                              let tasksCompleted = data["tasksCompleted"] as? Int,
                              let contributionPercentage = data["contributionPercentage"] as? Double else { return nil }
                        return TopContributor(username: username, tasksCompleted: tasksCompleted, contributionPercentage: contributionPercentage)
                    }
                    
                    analytics = PodAnalytics(
                        completionRate: completionRate,
                        activeMembers: activeMembers,
                        tasksCompleted: tasksCompleted,
                        totalTasks: totalTasks,
                        avgResponseTime: avgResponseTime,
                        taskProgress: taskProgress,
                        memberActivity: memberActivity,
                        topContributors: topContributors
                    )
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    // Fallback to mock data if there's an error
                    analytics = mockPodAnalytics
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Key Metrics Section
struct KeyMetricsSection: View {
    let analytics: PodAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Key Metrics".localized, action: {})
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                MetricCard(
                    title: "Completion Rate".localized,
                    value: "\(analytics.completionRate)%",
                    change: "+12%",
                    isPositive: true,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                MetricCard(
                    title: "Active Members".localized,
                    value: "\(analytics.activeMembers)",
                    change: "+2",
                    isPositive: true,
                    icon: "person.3"
                )
                
                MetricCard(
                    title: "Tasks Completed".localized,
                    value: "\(analytics.tasksCompleted)",
                    change: "+8",
                    isPositive: true,
                    icon: "checkmark.circle"
                )
                
                MetricCard(
                    title: "Avg. Response Time".localized,
                    value: "\(analytics.avgResponseTime)h",
                    change: "-2h",
                    isPositive: true,
                    icon: "clock"
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Progress Charts Section
struct ProgressChartsSection: View {
    let analytics: PodAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Progress Overview".localized, action: {})
            
            VStack(spacing: 20) {
                // Task Progress Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Task Progress".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    // Simple chart representation
                    VStack(spacing: 8) {
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(analytics.taskProgress, id: \.date) { data in
                                VStack {
                                    Text("\(data.value)")
                                        .font(.system(size: 10))
                                        .foregroundColor(Color.textSecondary)
                                    
                                    Rectangle()
                                        .fill(Color.accentGreen)
                                        .frame(width: 20, height: CGFloat(max(1, data.value * 10)))
                                        .cornerRadius(2)
                                    
                                    Text(data.date, style: .date)
                                        .font(.system(size: 8))
                                        .foregroundColor(Color.textSecondary)
                                }
                            }
                        }
                        .frame(height: 150)
                        
                        Text("Task Progress Over Time")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                
                // Member Activity Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Member Activity".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    // Simple bar chart representation
                    VStack(spacing: 8) {
                        VStack(spacing: 8) {
                            ForEach(analytics.memberActivity, id: \.member) { data in
                                HStack {
                                    Text(data.member)
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textPrimary)
                                        .frame(width: 80, alignment: .leading)
                                    
                                    Rectangle()
                                        .fill(Color.accentBlue)
                                        .frame(width: CGFloat(max(20, data.tasksCompleted * 15)), height: 20)
                                        .cornerRadius(4)
                                    
                                    Text("\(data.tasksCompleted)")
                                        .font(.system(size: 12))
                                        .foregroundColor(Color.textSecondary)
                                        .frame(width: 30, alignment: .trailing)
                                }
                            }
                        }
                        .frame(height: 150)
                        
                        Text("Member Activity")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Member Activity Section
struct MemberActivitySection: View {
    let analytics: PodAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Top Contributors".localized, action: {})
            
            VStack(spacing: 12) {
                ForEach(analytics.topContributors, id: \.username) { contributor in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.accentGreen)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(contributor.username.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(contributor.username)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)
                            
                            Text("\(contributor.tasksCompleted) tasks completed")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(contributor.contributionPercentage)%")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(Color.accentGreen)
                            
                            Text("contribution".localized)
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(Color.backgroundPrimary)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}



// MARK: - Metric Card
struct MetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentGreen)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 12))
                        .foregroundColor(isPositive ? Color.accentGreen : Color.error)
                    
                    Text(change)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isPositive ? Color.accentGreen : Color.error)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color.textPrimary)
                
                Text(title)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Additional Analytics Models
struct ProgressData {
    let date: Date
    let value: Int
}

struct Contributor {
    let username: String
    let tasksCompleted: Int
    let contributionPercentage: Int
}

struct StatusDistribution {
    let status: PodTask.TaskStatus
    let count: Int
    let percentage: Int
}

struct PerformanceTrend {
    let metric: String
    let change: String
    let isPositive: Bool
}

// MARK: - Mock Analytics Data
let mockPodAnalytics = PodAnalytics(
    completionRate: 78,
    activeMembers: 5,
    tasksCompleted: 24,
    totalTasks: 31,
    avgResponseTime: 4,
    taskProgress: [
        TaskProgressData(date: Date().addingTimeInterval(-518400), value: 5),
        TaskProgressData(date: Date().addingTimeInterval(-432000), value: 8),
        TaskProgressData(date: Date().addingTimeInterval(-345600), value: 12),
        TaskProgressData(date: Date().addingTimeInterval(-259200), value: 15),
        TaskProgressData(date: Date().addingTimeInterval(-172800), value: 18),
        TaskProgressData(date: Date().addingTimeInterval(-86400), value: 22),
        TaskProgressData(date: Date(), value: 24)
    ],
    memberActivity: [
        MemberActivityData(member: "Alex", tasksCompleted: 8),
        MemberActivityData(member: "Sarah", tasksCompleted: 6),
        MemberActivityData(member: "John", tasksCompleted: 5),
        MemberActivityData(member: "Maria", tasksCompleted: 3),
        MemberActivityData(member: "David", tasksCompleted: 2)
    ],
    topContributors: [
        TopContributor(username: "AlexChen", tasksCompleted: 8, contributionPercentage: 33.0),
        TopContributor(username: "SarahKim", tasksCompleted: 6, contributionPercentage: 25.0),
        TopContributor(username: "JohnSmith", tasksCompleted: 5, contributionPercentage: 21.0),
        TopContributor(username: "MariaGarcia", tasksCompleted: 3, contributionPercentage: 13.0),
        TopContributor(username: "DavidBrown", tasksCompleted: 2, contributionPercentage: 8.0)
    ]
) 