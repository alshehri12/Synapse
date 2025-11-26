//
//  BlockedUsersView.swift
//  Synapse
//
//  Blocked users management for App Store compliance
//

import SwiftUI

struct BlockedUsersView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var moderationManager = ContentModerationManager.shared

    var body: some View {
        List {
            if moderationManager.blockedUsers.isEmpty {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 48))
                            .foregroundColor(Color.textSecondary)

                        Text("No Blocked Users")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color.textPrimary)

                        Text("When you block someone, they won't be able to interact with you or see your content.")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                Section(header: Text("Blocked Users"), footer: Text("Blocked users can't see your content or interact with you.")) {
                    ForEach(Array(moderationManager.blockedUsers), id: \.self) { userId in
                        HStack {
                            // User Avatar
                            Circle()
                                .fill(Color.accentGreen.opacity(0.3))
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(Color.accentGreen)
                                )

                            VStack(alignment: .leading, spacing: 4) {
                                Text("User \(userId.prefix(8))")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Color.textPrimary)

                                Text("Blocked")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.textSecondary)
                            }

                            Spacer()

                            Button(action: {
                                unblockUser(userId)
                            }) {
                                Text("Unblock")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.accentGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .navigationTitle("Blocked Users")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func unblockUser(_ userId: String) {
        Task {
            do {
                try await moderationManager.unblockUser(userId: userId)
            } catch {
                print("❌ Error unblocking user: \(error)")
            }
        }
    }
}
