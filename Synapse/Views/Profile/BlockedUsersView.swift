//
//  BlockedUsersView.swift
//  Synapse
//
//  Created by Claude Code
//

import SwiftUI

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager

    @State private var blockedUsers: [BlockedUser] = []
    @State private var isLoading = true
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView("Loading blocked users...")
                } else if blockedUsers.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(blockedUsers) { user in
                            BlockedUserRow(user: user, onUnblock: {
                                unblockUser(user)
                            })
                        }
                    }
                }
            }
            .navigationTitle("Blocked Users")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .task {
                await loadBlockedUsers()
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.slash")
                .font(.system(size: 60))
                .foregroundColor(Color.textSecondary)

            Text("No Blocked Users")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            Text("When you block someone, they won't be able to interact with your content")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    private func loadBlockedUsers() async {
        do {
            blockedUsers = try await supabaseManager.getBlockedUsers()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isLoading = false
        }
    }

    private func unblockUser(_ user: BlockedUser) {
        Task {
            do {
                try await supabaseManager.unblockUser(userId: user.blockedUserId)
                await loadBlockedUsers()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

struct BlockedUserRow: View {
    let user: BlockedUser
    let onUnblock: () -> Void

    @State private var showConfirmation = false

    var body: some View {
        HStack {
            // User Avatar
            Circle()
                .fill(Color.accentGreen.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user.blockedUsername.prefix(1)).uppercased())
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color.accentGreen)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.blockedUsername)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                Text("Blocked \(timeAgo(from: user.blockedAt))")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textSecondary)
            }

            Spacer()

            Button("Unblock") {
                showConfirmation = true
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(Color.accentGreen)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .stroke(Color.accentGreen, lineWidth: 1.5)
            )
        }
        .padding(.vertical, 8)
        .alert("Unblock \(user.blockedUsername)?", isPresented: $showConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Unblock") {
                onUnblock()
            }
        } message: {
            Text("This user will be able to see and interact with your content again.")
        }
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.day, .hour, .minute], from: date, to: now)

        if let days = components.day, days > 0 {
            return "\(days)d ago"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours)h ago"
        } else if let minutes = components.minute, minutes > 0 {
            return "\(minutes)m ago"
        } else {
            return "Just now"
        }
    }
}

#Preview {
    BlockedUsersView()
}
