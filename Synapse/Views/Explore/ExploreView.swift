//
//  ExploreView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct ExploreView: View {
    @State private var searchText = ""
    @State private var selectedFilter: IdeaFilter = .all
    @State private var ideas: [IdeaSpark] = []
    @State private var isLoading = false
    @State private var showingSearch = false
    @State private var showingActivityFeed = false
    @State private var showingCreateIdea = false
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    enum IdeaFilter: String, CaseIterable {
        case all = "All"
        case sparking = "Sparking"
        case incubating = "Incubating"
        case launched = "Launched"
        case completed = "Completed"
    }
    
    var filteredIdeas: [IdeaSpark] {
        let filtered = ideas.filter { idea in
            if searchText.isEmpty { return true }
            return idea.title.localizedCaseInsensitiveContains(searchText) ||
                   idea.description.localizedCaseInsensitiveContains(searchText) ||
                   idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
        }
        
        if selectedFilter == .all { return filtered }
        return filtered.filter { $0.status.rawValue == selectedFilter.rawValue.lowercased() }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search and Filter Bar
                VStack(spacing: 12) {
                    HStack {
                        SearchBar(text: $searchText, placeholder: "Search ideas, tags, or users...".localized)
                        
                        Button(action: { showingSearch = true }) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 18))
                                .foregroundColor(Color.accentGreen)
                                .frame(width: 44, height: 44)
                                .background(Color.accentGreen.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    
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
                }
                .padding(.vertical, 16)
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
                        icon: "sparkles",
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
            .navigationTitle("Explore".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            showingActivityFeed = true
                        }) {
                            Image(systemName: "bell")
                                .font(.title2)
                                .foregroundColor(Color.textPrimary)
                        }
                        
                        Button(action: {
                            showingCreateIdea = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Spark".localized)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.accentGreen)
                            .cornerRadius(20)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Task {
                            await firebaseManager.debugIdeaSparksCollection()
                        }
                    }) {
                        Image(systemName: "ladybug")
                            .font(.title2)
                            .foregroundColor(Color.accentGreen)
                    }
                }
            }
            .onAppear {
                print("ExploreView appeared, loading ideas...")
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
                    print("CreateIdeaView dismissed, refreshing ideas...")
                    showingCreateIdea = false
                    // Add a small delay to ensure Firebase data is committed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        loadIdeas()
                    }
                })
            }
            .overlay(
                // Floating Action Button - Only show when there are ideas
                Group {
                    if !filteredIdeas.isEmpty && !isLoading {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Button(action: {
                                    showingCreateIdea = true
                                }) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 56, height: 56)
                                        .background(Color.accentGreen)
                                        .clipShape(Circle())
                                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                                }
                                .padding(.trailing, 20)
                                .padding(.bottom, 100) // Above tab bar
                            }
                        }
                    }
                }
            )
        }
    }
    
    private func loadIdeas() {
        print("Loading ideas...")
        isLoading = true
        
        Task {
            await loadIdeasAsync()
        }
    }
    
    private func refreshIdeas() async {
        print("Refreshing ideas...")
        await loadIdeasAsync()
    }
    
    private func loadIdeasAsync() async {
        do {
            let ideaData = try await firebaseManager.getPublicIdeaSparks()
            print("Loaded \(ideaData.count) ideas from Firebase")
            
                            await MainActor.run {
                    print("Processing \(ideaData.count) ideas from Firebase...")
                    ideas = ideaData.compactMap { data in
                        print("Processing idea data: \(data)")
                        
                        // Debug each field
                        let id = data["id"] as? String
                        let authorId = data["authorId"] as? String
                        let authorUsername = data["authorUsername"] as? String
                        let title = data["title"] as? String
                        let description = data["description"] as? String
                        let tags = data["tags"] as? [String]
                        let isPublic = data["isPublic"] as? Bool
                        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
                        let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue()
                        let likes = data["likes"] as? Int
                        let comments = data["comments"] as? Int
                        let statusString = data["status"] as? String
                        let status = statusString != nil ? IdeaSpark.IdeaStatus(rawValue: statusString!) : nil
                        
                        print("  Parsed fields:")
                        print("    id: \(id ?? "nil")")
                        print("    authorId: \(authorId ?? "nil")")
                        print("    authorUsername: \(authorUsername ?? "nil")")
                        print("    title: \(title ?? "nil")")
                        print("    description: \(description ?? "nil")")
                        print("    tags: \(tags ?? [])")
                        print("    isPublic: \(isPublic != nil ? String(describing: isPublic!) : "nil")")
                        print("    createdAt: \(createdAt != nil ? String(describing: createdAt!) : "nil")")
                        print("    updatedAt: \(updatedAt != nil ? String(describing: updatedAt!) : "nil")")
                        print("    likes: \(likes != nil ? String(describing: likes!) : "nil")")
                        print("    comments: \(comments != nil ? String(describing: comments!) : "nil")")
                        print("    statusString: \(statusString ?? "nil")")
                        print("    status: \(status?.rawValue ?? "nil")")
                        
                        guard let id = id,
                              let authorId = authorId,
                              let authorUsername = authorUsername,
                              let title = title,
                              let description = description,
                              let tags = tags,
                              let isPublic = isPublic,
                              let createdAt = createdAt,
                              let updatedAt = updatedAt,
                              let likes = likes,
                              let comments = comments,
                              let status = status else {
                            print("Failed to parse idea data - missing required fields")
                            return nil
                        }
                        
                        let idea = IdeaSpark(
                            id: id,
                            authorId: authorId,
                            authorUsername: authorUsername,
                            title: title,
                            description: description,
                            tags: tags,
                            isPublic: isPublic,
                            createdAt: createdAt,
                            updatedAt: updatedAt,
                            likes: likes,
                            comments: comments,
                            status: status
                        )
                        
                        print("  Successfully created IdeaSpark: \(idea.title)")
                        return idea
                    }
                    print("Final ideas count: \(ideas.count)")
                    isLoading = false
                }
        } catch {
            print("Error loading ideas: \(error)")
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
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
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
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentGreen.opacity(0.1))
                        .cornerRadius(8)
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
        guard let currentUser = firebaseManager.currentUser else { return }
        
        // This would need to be implemented to check if the current user has liked this idea
        // For now, we'll assume not liked
        isLiked = false
    }
    
    private func likeIdea() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        Task {
            do {
                try await firebaseManager.likeIdea(ideaId: idea.id, userId: currentUser.uid)
                await MainActor.run {
                    isLiked.toggle()
                }
            } catch {
                print("Error liking idea: \(error)")
            }
        }
    }
}




#Preview {
    ExploreView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
} 
