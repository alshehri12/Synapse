//
//  SearchView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    @State private var searchText = ""
    @State private var selectedCategory: SearchCategory = .all
    @State private var ideas: [IdeaSpark] = []
    @State private var pods: [IncubationProject] = []
    @State private var users: [UserProfile] = []
    @State private var isLoading = false
    @State private var showingFilters = false
    
    enum SearchCategory: String, CaseIterable {
        case all = "All"
        case ideas = "Ideas"
        case pods = "Pods"
        case users = "Users"
        case tags = "Tags"
    }
    
    var filteredResults: (ideas: [IdeaSpark], pods: [IncubationProject], users: [UserProfile]) {
        let filteredIdeas = ideas.filter { idea in
            if searchText.isEmpty { return true }
            return idea.title.localizedCaseInsensitiveContains(searchText) ||
                   idea.description.localizedCaseInsensitiveContains(searchText) ||
                   idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        let filteredPods = pods.filter { pod in
            if searchText.isEmpty { return true }
            return pod.name.localizedCaseInsensitiveContains(searchText) ||
                   pod.description.localizedCaseInsensitiveContains(searchText)
        }
        
        let filteredUsers = users.filter { user in
            if searchText.isEmpty { return true }
            return user.username.localizedCaseInsensitiveContains(searchText) ||
                   user.skills.contains { $0.localizedCaseInsensitiveContains(searchText) } ||
                   user.interests.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        return (filteredIdeas, filteredPods, filteredUsers)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Header
                VStack(spacing: 16) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.textSecondary)
                        
                        TextField("Search ideas, pods, users, or tags...".localized, text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(Color.textSecondary)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color.backgroundPrimary)
                    .cornerRadius(12)
                    
                    // Category Tabs
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(SearchCategory.allCases, id: \.self) { category in
                                FilterChip(
                                    title: category.rawValue.localized,
                                    isSelected: selectedCategory == category
                                ) {
                                    selectedCategory = category
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.backgroundPrimary)
                
                // Search Results
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if searchText.isEmpty {
                    // Trending Section
                    TrendingSection()
                } else {
                    SearchResultsSection(
                        ideas: filteredResults.ideas,
                        pods: filteredResults.pods,
                        users: filteredResults.users,
                        selectedCategory: selectedCategory
                    )
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Search".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingFilters = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .onAppear {
                loadSearchData()
            }
            .sheet(isPresented: $showingFilters) {
                SearchFiltersView()
            }
        }
    }
    
    private func loadSearchData() {
        isLoading = true
        
        Task {
            do {
                async let ideasTask = supabaseManager.getPublicIdeaSparks()
                async let podsTask = supabaseManager.getPublicPods()
                // TODO: Implement getAllUsers in SupabaseManager
                async let usersTask = Task { return [UserProfile]() }
                
                let (ideaData, podData, userData) = try await (ideasTask, podsTask, usersTask)
                
                // Get data from all tasks
                let allIdeas = ideaData
                let allPods = podData
                let allUsers = try await userData.value
                
                await MainActor.run {
                    ideas = allIdeas
                    pods = allPods
                    users = allUsers
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Trending Section
struct TrendingSection: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var trendingIdeas: [IdeaSpark] = []
    @State private var popularPods: [IncubationProject] = []
    @State private var topUsers: [UserProfile] = []
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Trending Ideas
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Trending Ideas".localized, action: {})
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            Text("Loading trending ideas...".localized)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 20)
                    } else if trendingIdeas.isEmpty {
                        Text("No trending ideas yet".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(trendingIdeas.prefix(5)) { idea in
                                    TrendingIdeaCard(idea: idea)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Popular Pods
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Popular Pods".localized, action: {})
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            Text("Loading popular pods...".localized)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 20)
                    } else if popularPods.isEmpty {
                        Text("No popular pods yet".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(popularPods.prefix(5)) { pod in
                                    TrendingPodCard(pod: pod)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Top Contributors
                VStack(alignment: .leading, spacing: 16) {
                    SectionHeader(title: "Top Contributors".localized, action: {})
                    
                    if isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            Text("Loading top contributors...".localized)
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 20)
                    } else if topUsers.isEmpty {
                        Text("No top contributors yet".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .padding(.horizontal, 20)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(topUsers.prefix(5)) { user in
                                UserRow(user: user)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
            .padding(.vertical, 16)
        }
        .onAppear {
            loadTrendingData()
        }
    }
    
    private func loadTrendingData() {
        isLoading = true
        
        Task {
            do {
                async let ideasTask = supabaseManager.getPublicIdeaSparks()
                async let podsTask = supabaseManager.getPublicPods()
                // TODO: Implement getAllUsers in SupabaseManager
                async let usersTask = Task { return [UserProfile]() }
                
                let (ideaData, podData, userData) = try await (ideasTask, podsTask, usersTask)
                
                await MainActor.run {
                    trendingIdeas = ideaData
                    popularPods = podData
                    
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Search Results Section
struct SearchResultsSection: View {
    let ideas: [IdeaSpark]
    let pods: [IncubationProject]
    let users: [UserProfile]
    let selectedCategory: SearchView.SearchCategory
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                switch selectedCategory {
                case .all:
                    if !ideas.isEmpty {
                        SectionHeader(title: "Ideas".localized, action: {})
                        ForEach(ideas.prefix(3)) { idea in
                            ExploreIdeaCard(idea: idea)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    if !pods.isEmpty {
                        SectionHeader(title: "Pods".localized, action: {})
                        ForEach(pods.prefix(3)) { pod in
                            PodCard(pod: pod)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                    if !users.isEmpty {
                        SectionHeader(title: "Users".localized, action: {})
                        ForEach(users.prefix(3)) { user in
                            UserRow(user: user)
                                .padding(.horizontal, 20)
                        }
                    }
                    
                case .ideas:
                    ForEach(ideas) { idea in
                        ExploreIdeaCard(idea: idea)
                            .padding(.horizontal, 20)
                    }
                    
                case .pods:
                    ForEach(pods) { pod in
                        PodCard(pod: pod)
                            .padding(.horizontal, 20)
                    }
                    
                case .users:
                    ForEach(users) { user in
                        UserRow(user: user)
                            .padding(.horizontal, 20)
                    }
                    
                case .tags:
                    TagsSection(searchText: "")
                }
            }
            .padding(.vertical, 16)
        }
    }
}

// MARK: - Trending Idea Card
struct TrendingIdeaCard: View {
    let idea: IdeaSpark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(idea.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.textPrimary)
                .lineLimit(2)
            
            Text(idea.description)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(3)
            
            HStack {
                ForEach(idea.tags.prefix(2), id: \.self) { tag in
                    Text(tag)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.accentGreen.opacity(0.1))
                        .foregroundColor(Color.accentGreen)
                        .cornerRadius(8)
                }
                
                Spacer()
                
                Text("\(idea.likes)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .frame(width: 200)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Trending Pod Card
struct TrendingPodCard: View {
    let pod: IncubationProject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(pod.name.prefix(1)).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(pod.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                    
                    Text("\(pod.members.count) members")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
            }
            
            Text(pod.description)
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
                .lineLimit(2)
            
                                        ProjectStatusBadge(status: pod.status)
        }
        .padding(16)
        .frame(width: 200)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - User Row
struct UserRow: View {
    let user: UserProfile
    @State private var isFollowing = false
    @State private var isLoading = false
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.accentGreen)
                .frame(width: 48, height: 48)
                .overlay(
                    Text(String(user.username.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(user.username)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                
                if let bio = user.bio {
                    Text(bio)
                        .font(.system(size: 14))
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(2)
                }
                
                HStack {
                    Text("\(user.ideasSparked) ideas")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                    
                    Text("•")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                    
                    Text("\(user.projectsContributed) projects")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
            
            Button(isFollowing ? "Unfollow".localized : "Follow".localized) {
                toggleFollow()
            }
            .font(.system(size: 14, weight: .medium))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isFollowing ? Color.textSecondary : Color.accentGreen)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isLoading)
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
        .onAppear {
            checkFollowStatus()
        }
    }
    
    private func checkFollowStatus() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        Task {
            do {
                // TODO: Implement isFollowing in SupabaseManager
                let following = false
                await MainActor.run {
                    isFollowing = following
                }
            } catch {
                print("Error checking follow status: \(error)")
            }
        }
    }
    
    private func toggleFollow() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                if isFollowing {
                    // TODO: Implement unfollowUser in SupabaseManager
                    print("✅ Unfollow user requested: \(user.id)")
                } else {
                    // TODO: Implement followUser in SupabaseManager
                    print("✅ Follow user requested: \(user.id)")
                }
                
                await MainActor.run {
                    isFollowing.toggle()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                }
                print("Error toggling follow: \(error)")
            }
        }
    }
}

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.textPrimary)
            
            Spacer()
            
            Button("See All".localized, action: action)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.accentGreen)
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Search Filters View
struct SearchFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedStatus: IdeaSpark.IdeaStatus?
    @State private var selectedTags: [String] = []
    @State private var dateRange: DateRange = .allTime
    
    enum DateRange: String, CaseIterable {
        case allTime = "All Time"
        case lastWeek = "Last Week"
        case lastMonth = "Last Month"
        case lastYear = "Last Year"
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Status".localized) {
                    ForEach(IdeaSpark.IdeaStatus.allCases, id: \.self) { status in
                        HStack {
                            Text(status.rawValue.capitalized.localized)
                            Spacer()
                            if selectedStatus == status {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.accentGreen)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedStatus = selectedStatus == status ? nil : status
                        }
                    }
                }
                
                Section("Date Range".localized) {
                    ForEach(DateRange.allCases, id: \.self) { range in
                        HStack {
                            Text(range.rawValue.localized)
                            Spacer()
                            if dateRange == range {
                                Image(systemName: "checkmark")
                                    .foregroundColor(Color.accentGreen)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            dateRange = range
                        }
                    }
                }
            }
            .navigationTitle("Filters".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset".localized) {
                        selectedStatus = nil
                        selectedTags = []
                        dateRange = .allTime
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Tags Section
struct TagsSection: View {
    let searchText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "Popular Tags".localized, action: {})
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(popularTags, id: \.self) { tag in
                    TagCard(tag: tag)
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private let popularTags = ["AI", "Education", "Sustainability", "Mobile", "Web", "Design", "Health", "Finance"]
}

// MARK: - Tag Card
struct TagCard: View {
    let tag: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text("#\(tag)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.accentGreen)
            
            Text("1.2k ideas")
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

// MARK: - Mock Data
let mockUsers: [UserProfile] = [
    UserProfile(
        id: "user1",
        username: "AlexChen",
        email: "alex@example.com",
        bio: "Full-stack developer passionate about AI",
        avatarURL: nil,
        skills: ["Swift", "Python", "Firebase"],
        interests: ["AI", "Education"],
        ideasSparked: 5,
        projectsContributed: 3,
        dateJoined: Date().addingTimeInterval(-7776000)
    ),
    UserProfile(
        id: "user2",
        username: "SarahKim",
        email: "sarah@example.com",
        bio: "UX Designer focused on sustainable solutions",
        avatarURL: nil,
        skills: ["UI/UX", "Figma", "Prototyping"],
        interests: ["Sustainability", "Design"],
        ideasSparked: 3,
        projectsContributed: 2,
        dateJoined: Date().addingTimeInterval(-6048000)
    )
] 
