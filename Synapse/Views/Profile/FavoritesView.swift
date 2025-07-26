//
//  FavoritesView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import FirebaseFirestore

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var firebaseManager: FirebaseManager
    @State private var favorites: [[String: Any]] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if isLoading {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                        .scaleEffect(1.2)
                    Spacer()
                } else if favorites.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "star")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("No favorites yet".localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("Save ideas you like to view them later".localized)
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favorites.indices, id: \.self) { index in
                                let favorite = favorites[index]
                                FavoriteCard(favorite: favorite) {
                                    // Remove from favorites
                                    removeFromFavorites(favorite: favorite)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Favorites".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done".localized) {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadFavorites()
            }
        }
    }
    
    private func loadFavorites() {
        guard let currentUser = firebaseManager.currentUser else { return }
        
        isLoading = true
        
        Task {
            do {
                favorites = try await firebaseManager.getUserFavorites(userId: currentUser.uid)
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                print("Error loading favorites: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
    
    private func removeFromFavorites(favorite: [String: Any]) {
        guard let currentUser = firebaseManager.currentUser,
              let ideaId = favorite["ideaId"] as? String else { return }
        
        Task {
            do {
                try await firebaseManager.removeFromFavorites(userId: currentUser.uid, ideaId: ideaId)
                
                await MainActor.run {
                    // Remove from local array
                    favorites.removeAll { fav in
                        fav["ideaId"] as? String == ideaId
                    }
                }
            } catch {
                print("Error removing from favorites: \(error)")
            }
        }
    }
}

struct FavoriteCard: View {
    let favorite: [String: Any]
    let onRemove: () -> Void
    
    private var ideaData: [String: Any] {
        return favorite["ideaData"] as? [String: Any] ?? [:]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with title and remove button
            HStack {
                Text(ideaData["title"] as? String ?? "")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(2)
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.accentOrange)
                }
            }
            
            // Description
            Text(ideaData["description"] as? String ?? "")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .lineLimit(3)
            
            // Tags
            if let tags = ideaData["tags"] as? [String], !tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
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
            
            // Author and Stats
            HStack {
                // Author
                HStack(spacing: 4) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 12))
                    Text(ideaData["authorUsername"] as? String ?? "")
                        .font(.system(size: 12))
                }
                .foregroundColor(Color.textSecondary)
                
                Spacer()
                
                // Stats
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "heart")
                            .font(.system(size: 12))
                        Text("\(ideaData["likes"] as? Int ?? 0)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color.textSecondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "message")
                            .font(.system(size: 12))
                        Text("\(ideaData["comments"] as? Int ?? 0)")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(Color.textSecondary)
                }
            }
            
            // Date added to favorites
            if let createdAt = favorite["createdAt"] as? Timestamp {
                Text("Added \(createdAt.dateValue().formatted(date: .abbreviated, time: .omitted))".localized)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
} 