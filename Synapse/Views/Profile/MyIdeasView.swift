//
//  MyIdeasView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Supabase

struct MyIdeasView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var ideas: [IdeaSpark] = []
    @State private var isLoading = true
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab Selector
                Picker("Idea Type", selection: $selectedTab) {
                    Text("Public".localized).tag(0)
                    Text("Private".localized).tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if ideas.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "lightbulb")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textSecondary)
                        
                        Text(selectedTab == 0 ? "No public ideas yet".localized : "No private ideas yet".localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                        
                        Text(selectedTab == 0 ? "Share your ideas with the community".localized : "Keep your ideas private for now".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(ideas.indices, id: \.self) { index in
                                let idea = ideas[index]
                                IdeaCard(idea: idea)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("My Ideas".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Text("Done".localized)
                    }
                }
            }
            .onAppear {
                loadIdeas()
            }
            .onChange(of: selectedTab) { _ in
                loadIdeas()
            }
        }
    }
    
    private func loadIdeas() {
        guard let currentUser = supabaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                if selectedTab == 0 {
                    // Load public ideas
                    ideas = try await supabaseManager.getUserIdeas(userId: currentUser.uid)
                } else {
                    // Load private ideas
                    ideas = try await supabaseManager.getUserPrivateIdeas(userId: currentUser.uid)
                }
                
                await MainActor.run {
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
}

struct IdeaCard: View {
    let idea: IdeaSpark
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title with Private badge
            HStack(alignment: .top, spacing: 8) {
                Text(idea.title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)

                if !idea.isPublic {
                    Text("Private".localized)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(6)
                }
            }
            
            // Description
            Text(idea.description)
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(3)
            
            // Tags
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(idea.tags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.accentGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.accentGreen.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }
            
            // Stats
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "heart")
                        .font(.system(size: 12))
                    Text("\(idea.likes)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 12))
                    Text("\(idea.comments)")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                // Date
                Text(idea.createdAt, style: .date)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
} 