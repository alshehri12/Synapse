//
//  UserAnalyticsView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct UserAnalyticsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var analytics: [String: Any] = [:]
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            .scaleEffect(1.2)
                            .frame(height: 200)
                    } else {
                        // Overview Stats
                        OverviewStatsSection(analytics: analytics)
                        
                        // Activity Timeline
                        ActivityTimelineSection(analytics: analytics)
                        
                        // Top Contributions
                        TopContributionsSection(analytics: analytics)
                        
                        // Engagement Metrics
                        EngagementMetricsSection(analytics: analytics)
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Analytics".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
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
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
                        Task<Void, Never> {
                    do {
                        // Get user's ideas
                        let publicIdeas = try await supabaseManager.getPublicIdeaSparks()
                        let privateIdeas: [IdeaSpark] = []  // Placeholder until getUserPrivateIdeas is implemented
                        let totalIdeas = publicIdeas.count + privateIdeas.count
                
                // Get user's pods
                let userPods = try await supabaseManager.getUserPods(userId: currentUser.id.uuidString)
                
                // Calculate engagement metrics
                let totalLikes = publicIdeas.reduce(0) { sum, idea in
                    sum + idea.likes
                }
                
                let totalComments = publicIdeas.reduce(0) { sum, idea in
                    sum + idea.comments
                }
                
                // Calculate activity over time (last 7 days)
                let calendar = Calendar.current
                let endDate = Date()
                let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
                
                var activityData: [[String: Any]] = []
                for i in 0..<7 {
                    let date = calendar.date(byAdding: .day, value: -i, to: endDate) ?? endDate
                    let dayStart = calendar.startOfDay(for: date)
                    let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
                    
                    let ideasOnDay = publicIdeas.filter { idea in
                        return idea.createdAt >= dayStart && idea.createdAt < dayEnd
                    }.count
                    
                    activityData.append([
                        "date": dayStart,
                        "ideas": ideasOnDay
                    ])
                }
                
                // Calculate top performing ideas
                let topIdeas = publicIdeas
                    .sorted { idea1, idea2 in
                        return idea1.likes > idea2.likes
                    }
                    .prefix(3)
                    .map { idea in
                        [
                            "title": idea.title,
                            "likes": idea.likes,
                            "comments": idea.comments
                        ]
                    }
                
                let analyticsData: [String: Any] = [
                    "totalIdeas": totalIdeas,
                    "publicIdeas": publicIdeas.count,
                    "privateIdeas": privateIdeas.count,
                    "totalPods": userPods.count,
                    "totalLikes": totalLikes,
                    "totalComments": totalComments,
                    "avgLikesPerIdea": totalIdeas > 0 ? Double(totalLikes) / Double(totalIdeas) : 0.0,
                    "avgCommentsPerIdea": totalIdeas > 0 ? Double(totalComments) / Double(totalIdeas) : 0.0,
                    "activityData": activityData,
                    "topIdeas": topIdeas,
                    "memberSince": currentUser.createdAt
                ]
                
                await MainActor.run {
                    analytics = analyticsData
                    isLoading = false
                }
            } catch {
                print("Error loading analytics: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Overview Stats Section
struct OverviewStatsSection: View {
    let analytics: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "Total Ideas".localized,
                    value: "\(analytics["totalIdeas"] as? Int ?? 0)",
                    icon: "lightbulb",
                    color: Color.accentOrange
                )
                
                StatCard(
                    title: "Active Pods".localized,
                    value: "\(analytics["totalPods"] as? Int ?? 0)",
                    icon: "person.3",
                    color: Color.accentGreen
                )
                
                StatCard(
                    title: "Total Likes".localized,
                    value: "\(analytics["totalLikes"] as? Int ?? 0)",
                    icon: "heart",
                    color: Color.red
                )
                
                StatCard(
                    title: "Total Comments".localized,
                    value: "\(analytics["totalComments"] as? Int ?? 0)",
                    icon: "message",
                    color: Color.accentBlue
                )
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Activity Timeline Section
struct ActivityTimelineSection: View {
    let analytics: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Activity (Last 7 Days)".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if let activityData = analytics["activityData"] as? [[String: Any]] {
                    ForEach(Array(activityData.enumerated()), id: \.offset) { index, activity in
                        if let date = activity["date"] as? Date,
                           let ideas = activity["ideas"] as? Int {
                            UserActivityRow(date: date, ideas: ideas)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct UserActivityRow: View {
    let date: Date
    let ideas: Int
    
    var body: some View {
        HStack {
            Text(date, style: .date)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .frame(width: 80, alignment: .leading)
            
            HStack(spacing: 4) {
                ForEach(0..<min(ideas, 5), id: \.self) { _ in
                    Circle()
                        .fill(Color.accentGreen)
                        .frame(width: 8, height: 8)
                }
                
                if ideas > 5 {
                    Text("+\(ideas - 5)")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
            
            Text("\(ideas) ideas".localized)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}

// MARK: - Top Contributions Section
struct TopContributionsSection: View {
    let analytics: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Top Performing Ideas".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 12) {
                if let topIdeas = analytics["topIdeas"] as? [[String: Any]] {
                    ForEach(topIdeas.indices, id: \.self) { index in
                        let idea = topIdeas[index]
                        TopIdeaRow(
                            rank: index + 1,
                            title: idea["title"] as? String ?? "",
                            likes: idea["likes"] as? Int ?? 0,
                            comments: idea["comments"] as? Int ?? 0
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct TopIdeaRow: View {
    let rank: Int
    let title: String
    let likes: Int
    let comments: Int
    
    var body: some View {
        HStack {
            Text("#\(rank)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.accentGreen)
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                    Text("\(likes)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 12))
                    Text("\(comments)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
}

// MARK: - Engagement Metrics Section
struct EngagementMetricsSection: View {
    let analytics: [String: Any]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Engagement Metrics".localized)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 16) {
                MetricRow(
                    title: "Avg. Likes per Idea".localized,
                    value: String(format: "%.1f", analytics["avgLikesPerIdea"] as? Double ?? 0.0),
                    icon: "heart.fill",
                    color: Color.red
                )
                
                MetricRow(
                    title: "Avg. Comments per Idea".localized,
                    value: String(format: "%.1f", analytics["avgCommentsPerIdea"] as? Double ?? 0.0),
                    icon: "message.fill",
                    color: Color.accentBlue
                )
                
                if let memberSince = analytics["memberSince"] as? Date {
                    MetricRow(
                        title: "Member Since".localized,
                        value: memberSince.formatted(date: .abbreviated, time: .omitted),
                        icon: "calendar",
                        color: Color.accentGreen
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct MetricRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    init(title: String, value: String, icon: String, color: Color) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
    }
    

    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
    }
} 