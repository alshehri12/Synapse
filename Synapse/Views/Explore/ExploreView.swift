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
        case new = "New"
        case active = "Active"
        case completed = "Completed"
    }
    
    var filteredIdeas: [IdeaSpark] {
        let filtered = ideas.filter { idea in
            if searchText.isEmpty { return true }
            return idea.title.localizedCaseInsensitiveContains(searchText) ||
                   idea.description.localizedCaseInsensitiveContains(searchText) ||
                   idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        switch selectedFilter {
        case .all:
            return filtered
        case .new:
            return filtered.sorted { $0.createdAt > $1.createdAt }
        case .active:
            return filtered.filter { $0.status == .incubating || $0.status == .planning }
        case .completed:
            return filtered.filter { $0.status == .launched || $0.status == .completed }
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

                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(IdeaFilter.allCases, id: \.self) { filter in
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
                .padding(.vertical, 12)
                .background(Color.backgroundPrimary)
                
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
    
    var body: some View {
        Text(status.rawValue.localized.capitalized)
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
                
                Button(action: { showingDetail = true }) {
                    Text("Join Pod".localized)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.accentGreen)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentGreen.opacity(0.1))
                        .cornerRadius(8)
                        .fixedSize(horizontal: true, vertical: false)
                }
                .buttonStyle(PlainButtonStyle())
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
        .onAppear {
            checkIfLiked()
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
