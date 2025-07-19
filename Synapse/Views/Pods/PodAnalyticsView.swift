//
//  PodAnalyticsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Charts

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
                        
                        // Task Insights
                        TaskInsightsSection(analytics: analytics)
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
        // TODO: Load analytics from Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            analytics = mockPodAnalytics
            isLoading = false
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
                    
                    Chart {
                        ForEach(analytics.taskProgress, id: \.date) { data in
                            LineMark(
                                x: .value("Date", data.date),
                                y: .value("Tasks", data.value)
                            )
                            .foregroundStyle(Color.accentGreen)
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
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
                    
                    Chart {
                        ForEach(analytics.memberActivity, id: \.member) { data in
                            BarMark(
                                x: .value("Member", data.member),
                                y: .value("Tasks", data.tasksCompleted)
                            )
                            .foregroundStyle(Color.accentBlue)
                        }
                    }
                    .frame(height: 200)
                    .chartXAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic) { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
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

// MARK: - Task Insights Section
struct TaskInsightsSection: View {
    let analytics: PodAnalytics
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Task Insights".localized, action: {})
            
            VStack(spacing: 16) {
                // Task Status Distribution
                VStack(alignment: .leading, spacing: 12) {
                    Text("Task Status Distribution".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    HStack(spacing: 16) {
                        ForEach(analytics.taskStatusDistribution, id: \.status) { distribution in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(statusColor(for: distribution.status))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Text("\(distribution.count)")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(distribution.status.rawValue.capitalized.localized)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(Color.textPrimary)
                                
                                Text("\(distribution.percentage)%")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                
                // Performance Trends
                VStack(alignment: .leading, spacing: 12) {
                    Text("Performance Trends".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    VStack(spacing: 12) {
                        ForEach(analytics.performanceTrends, id: \.metric) { trend in
                            HStack {
                                Text(trend.metric.localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textPrimary)
                                
                                Spacer()
                                
                                HStack(spacing: 4) {
                                    Image(systemName: trend.isPositive ? "arrow.up" : "arrow.down")
                                        .font(.system(size: 12))
                                        .foregroundColor(trend.isPositive ? Color.accentGreen : Color.error)
                                    
                                    Text(trend.change)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(trend.isPositive ? Color.accentGreen : Color.error)
                                }
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(trend.isPositive ? Color.accentGreen.opacity(0.1) : Color.error.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding(20)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func statusColor(for status: PodTask.TaskStatus) -> Color {
        switch status {
        case .todo:
            return Color.textSecondary
        case .inProgress:
            return Color.accentBlue
        case .completed:
            return Color.accentGreen
        case .cancelled:
            return Color.error
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

// MARK: - Analytics Models
struct PodAnalytics {
    let completionRate: Int
    let activeMembers: Int
    let tasksCompleted: Int
    let avgResponseTime: Int
    let taskProgress: [ProgressData]
    let memberActivity: [MemberActivityData]
    let topContributors: [Contributor]
    let taskStatusDistribution: [StatusDistribution]
    let performanceTrends: [PerformanceTrend]
}

struct ProgressData {
    let date: Date
    let value: Int
}

struct MemberActivityData {
    let member: String
    let tasksCompleted: Int
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
    avgResponseTime: 4,
    taskProgress: [
        ProgressData(date: Date().addingTimeInterval(-518400), value: 5),
        ProgressData(date: Date().addingTimeInterval(-432000), value: 8),
        ProgressData(date: Date().addingTimeInterval(-345600), value: 12),
        ProgressData(date: Date().addingTimeInterval(-259200), value: 15),
        ProgressData(date: Date().addingTimeInterval(-172800), value: 18),
        ProgressData(date: Date().addingTimeInterval(-86400), value: 22),
        ProgressData(date: Date(), value: 24)
    ],
    memberActivity: [
        MemberActivityData(member: "Alex", tasksCompleted: 8),
        MemberActivityData(member: "Sarah", tasksCompleted: 6),
        MemberActivityData(member: "John", tasksCompleted: 5),
        MemberActivityData(member: "Maria", tasksCompleted: 3),
        MemberActivityData(member: "David", tasksCompleted: 2)
    ],
    topContributors: [
        Contributor(username: "AlexChen", tasksCompleted: 8, contributionPercentage: 33),
        Contributor(username: "SarahKim", tasksCompleted: 6, contributionPercentage: 25),
        Contributor(username: "JohnSmith", tasksCompleted: 5, contributionPercentage: 21),
        Contributor(username: "MariaGarcia", tasksCompleted: 3, contributionPercentage: 13),
        Contributor(username: "DavidBrown", tasksCompleted: 2, contributionPercentage: 8)
    ],
    taskStatusDistribution: [
        StatusDistribution(status: .completed, count: 24, percentage: 78),
        StatusDistribution(status: .inProgress, count: 4, percentage: 13),
        StatusDistribution(status: .todo, count: 2, percentage: 6),
        StatusDistribution(status: .cancelled, count: 1, percentage: 3)
    ],
    performanceTrends: [
        PerformanceTrend(metric: "Task Completion", change: "+12%", isPositive: true),
        PerformanceTrend(metric: "Member Engagement", change: "+8%", isPositive: true),
        PerformanceTrend(metric: "Response Time", change: "-2h", isPositive: true),
        PerformanceTrend(metric: "Quality Score", change: "+5%", isPositive: true)
    ]
) 