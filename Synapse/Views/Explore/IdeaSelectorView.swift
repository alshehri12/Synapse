//
//  IdeaSelectorView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct IdeaSelectorView: View {
    @Binding var selectedIdea: IdeaSpark?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    
    @State private var ideas: [IdeaSpark] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.textSecondary)
                    
                    TextField("Search ideas".localized, text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(12)
                .background(Color.backgroundPrimary)
                .cornerRadius(12)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                // Ideas List
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
                        message: searchText.isEmpty ? "Create an idea first".localized : "No ideas match your search".localized
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredIdeas) { idea in
                                IdeaCard(
                                    idea: idea,
                                    isSelected: selectedIdea?.id == idea.id,
                                    action: {
                                        selectedIdea = idea
                                        dismiss()
                                    }
                                )
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Select Idea".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadIdeas()
            }
        }
    }
    
    private var filteredIdeas: [IdeaSpark] {
        if searchText.isEmpty {
            return ideas
        } else {
            return ideas.filter { idea in
                idea.title.localizedCaseInsensitiveContains(searchText) ||
                idea.description.localizedCaseInsensitiveContains(searchText) ||
                idea.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    private func loadIdeas() {
        isLoading = true
        // TODO: Load ideas from Firebase
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            ideas = mockIdeas
            isLoading = false
        }
    }
}

// MARK: - Idea Card
struct IdeaCard: View {
    let idea: IdeaSpark
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.accentGreen : Color.textSecondary)
                
                // Idea Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(idea.title)
                        .font(.system(size: 16, weight: .semibold))
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
                                ForEach(idea.tags.prefix(3), id: \.self) { tag in
                                    Text(tag)
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.accentGreen)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.accentGreen.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                
                                if idea.tags.count > 3 {
                                    Text("+\(idea.tags.count - 3)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(Color.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.backgroundSecondary)
                                        .cornerRadius(8)
                                }
                            }
                        }
                    }
                    
                    // Stats
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "heart")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                            
                            Text("\(idea.likes)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: "message")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                            
                            Text("\(idea.comments)")
                                .font(.system(size: 12))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        Text(idea.status.rawValue.localized.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor)
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding(16)
            .background(isSelected ? Color.accentGreen.opacity(0.1) : Color.backgroundPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentGreen : Color.border, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch idea.status {
        case .planning: return Color.accentBlue
        case .sparking: return Color.accentOrange
        case .incubating: return Color.accentBlue
        case .launched: return Color.accentGreen
        case .completed: return Color.success
        case .onHold: return Color.warning
        case .cancelled: return Color.textSecondary
        }
    }
}

// MARK: - Mock Ideas
let mockIdeas: [IdeaSpark] = [
    IdeaSpark(
        id: "idea1",
        authorId: "user1",
        authorUsername: "AlexChen",
        title: "AI Study Assistant",
        description: "An intelligent app that helps students create personalized study plans and track progress using AI algorithms.",
        tags: ["AI", "Education", "Productivity"],
        isPublic: true,
        createdAt: Date().addingTimeInterval(-86400),
        updatedAt: Date().addingTimeInterval(-3600),
        likes: 24,
        comments: 8,
        status: .incubating
    ),
    IdeaSpark(
        id: "idea2",
        authorId: "user2",
        authorUsername: "SarahKim",
        title: "Sustainable Food Network",
        description: "Connecting local farmers with consumers to reduce food waste and support sustainable agriculture.",
        tags: ["Sustainability", "Food", "Local Business"],
        isPublic: true,
        createdAt: Date().addingTimeInterval(-172800),
        updatedAt: Date().addingTimeInterval(-7200),
        likes: 18,
        comments: 12,
        status: .sparking
    ),
    IdeaSpark(
        id: "idea3",
        authorId: "user3",
        authorUsername: "MarcusRodriguez",
        title: "Mental Health Companion",
        description: "A mobile app that provides daily mental health check-ins, mood tracking, and personalized wellness recommendations.",
        tags: ["Health", "Mental Health", "Wellness"],
        isPublic: true,
        createdAt: Date().addingTimeInterval(-259200),
        updatedAt: Date().addingTimeInterval(-10800),
        likes: 31,
        comments: 15,
        status: .launched
    )
]

#Preview {
    IdeaSelectorView(selectedIdea: .constant(nil))
        .environmentObject(LocalizationManager.shared)
} 