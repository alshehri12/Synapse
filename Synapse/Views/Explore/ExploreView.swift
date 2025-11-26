//
//  ExploreView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedFilter: IdeaFilter = .all
    @State private var ideas: [IdeaSpark] = []
    @State private var isLoading = false
    @State private var showingSearch = false
    @State private var showingActivityFeed = false
    @State private var showingCreateIdea = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    enum IdeaFilter: String, CaseIterable {
        case all = "All"
    }

    var filteredIdeas: [IdeaSpark] {
        return ideas.filter { idea in
            if searchText.isEmpty { return true }
            return idea.title.localizedCaseInsensitiveContains(searchText) ||
                   idea.description.localizedCaseInsensitiveContains(searchText) ||
                   idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Elegant Header
                ExploreHeader(
                    searchText: $searchText,
                    onActivityTap: { showingActivityFeed = true },
                    onCreateIdea: { showingCreateIdea = true }
                )
                .environmentObject(localizationManager)

                // Ideas Feed
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if filteredIdeas.isEmpty {
                    EmptyStateView(
                        icon: "lightbulb",
                        title: "No ideas found".localized,
                        message: searchText.isEmpty ? "Be the first to spark an idea!".localized : "Try adjusting your search or filters".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredIdeas) { idea in
                                ExploreIdeaCard(idea: idea)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationBarHidden(true)
            .onAppear {
                loadIdeas()
            }
            .refreshable {
                await refreshIdeas()
            }
            .sheet(isPresented: $showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $showingActivityFeed) {
                ActivityFeedView()
            }
            .fullScreenCover(isPresented: $showingCreateIdea) {
                CreateIdeaView(onDismiss: {
                    showingCreateIdea = false
                    // Add a small delay to ensure data is committed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadIdeas()
                    }
                })
            }

        }
    }
    
    private func loadIdeas() {
        isLoading = true
        
        Task {
            await loadIdeasAsync()
        }
    }
    
    private func refreshIdeas() async {
        await loadIdeasAsync()
    }
    
    private func loadIdeasAsync() async {
        do {
            print("🔄 ExploreView: Loading ideas...")
            let ideaData = try await supabaseManager.getPublicIdeaSparks()
            
            await MainActor.run {
                print("📱 ExploreView: Received \(ideaData.count) ideas")
                ideas = ideaData
                isLoading = false
            }
        } catch {
            print("❌ ExploreView: Error loading ideas - \(error)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Color.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color.textSecondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.backgroundSecondary)
        .cornerRadius(12)
        .padding(.horizontal, 20)
    }
}





// MARK: - Status Badge
struct StatusBadge: View {
    let status: IdeaSpark.IdeaStatus

    var statusColor: Color {
        switch status {
        case .sparking: return Color.accentOrange
        case .incubating: return Color.accentBlue
        case .launched: return Color.accentGreen
        case .completed: return Color.success
        case .planning: return Color.accentBlue
        case .onHold: return Color.warning
        case .cancelled: return Color.textSecondary
        }
    }

    var statusLabel: String {
        switch status {
        case .sparking: return "New Idea"
        case .incubating: return "In Development"
        case .launched: return "Launched"
        case .completed: return "Completed"
        case .planning: return "Planning"
        case .onHold: return "On Hold"
        case .cancelled: return "Cancelled"
        }
    }

    var body: some View {
        Text(statusLabel.localized)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(Color.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(8)
    }
}

// MARK: - Explore Idea Card
struct ExploreIdeaCard: View {
    let idea: IdeaSpark
    @State private var isLiked = false
    @State private var showingDetail = false
    @State private var showingOptions = false
    @State private var showingReportSheet = false
    @StateObject private var moderationManager = ContentModerationManager.shared
    @EnvironmentObject private var supabaseManager: SupabaseManager

    var body: some View {
        Button(action: { showingDetail = true }) {
            VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.accentGreen)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(idea.authorUsername.prefix(1)).uppercased())
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(idea.authorUsername)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.textPrimary)

                    Text(idea.createdAt.timeAgoDisplay())
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }

                Spacer()

                StatusBadge(status: idea.status)

                // Three-dot menu for reporting
                if idea.authorId != supabaseManager.currentUser?.id.uuidString {
                    Button(action: { showingOptions = true }) {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                Text(idea.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)
                
                Text(idea.description)
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                    .lineLimit(3)
                
                // Tags
                if !idea.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(idea.tags.prefix(5), id: \.self) { tag in
                                Text(tag)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(Color.accentGreen)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentGreen.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                Button(action: likeIdea) {
                    HStack(spacing: 4) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 14))
                            .foregroundColor(isLiked ? .red : Color.textSecondary)

                        Text("\(idea.likes)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { showingDetail = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)

                        Text("\(idea.comments)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
            }
            }
            .padding(16)
            .background(Color.backgroundPrimary)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            IdeaDetailView(idea: idea)
        }
        .sheet(isPresented: $showingReportSheet) {
            ReportContentView(
                contentId: idea.id,
                contentType: "idea",
                reportedUserId: idea.authorId
            )
        }
        .actionSheet(isPresented: $showingOptions) {
            ActionSheet(
                title: Text("Idea Options"),
                buttons: [
                    .default(Text("Report Idea")) {
                        showingReportSheet = true
                    },
                    .destructive(Text("Block User")) {
                        blockUser(userId: idea.authorId)
                    },
                    .cancel()
                ]
            )
        }
        .onAppear {
            checkIfLiked()
        }
    }

    private func blockUser(userId: String) {
        Task {
            do {
                try await moderationManager.blockUser(userId: userId)
                print("✅ User blocked successfully")
            } catch {
                print("❌ Error blocking user: \(error)")
            }
        }
    }
    
    private func checkIfLiked() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        // This would need to be implemented to check if the current user has liked this idea
        // For now, we'll assume not liked
        isLiked = false
    }
    
    private func likeIdea() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        Task {
            do {
                try await supabaseManager.likeIdea(ideaId: idea.id, userId: currentUser.uid)
                await MainActor.run {
                    isLiked.toggle()
                }
                print("✅ Like action completed for idea: \(idea.id)")
            } catch {
                print("❌ Error liking idea: \(error.localizedDescription)")
            }
        }
    }
}




#Preview {
    ExploreView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
} 
