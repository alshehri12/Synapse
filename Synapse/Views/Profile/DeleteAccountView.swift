//
//  DeleteAccountView.swift
//  Synapse
//
//  Created by Claude Code
//

import SwiftUI

struct DeleteAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @State private var showDeleteConfirmation = false
    @State private var showFinalWarning = false
    @State private var deleteReason = ""
    @State private var isDeleting = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account Info Section
                    accountInfoSection

                    // Danger Zone
                    dangerZoneSection
                }
                .padding(24)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Continue", role: .destructive) {
                    showFinalWarning = true
                }
            } message: {
                Text("Are you sure you want to delete your account? This action cannot be undone.")
            }
            .alert("⚠️ Final Warning", isPresented: $showFinalWarning) {
                Button("Cancel", role: .cancel) {}
                Button("Delete My Account", role: .destructive) {
                    requestAccountDeletion()
                }
            } message: {
                Text("Your account will be scheduled for deletion in 30 days. During this period, you can cancel the deletion by logging in. After 30 days, ALL your data will be permanently deleted.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Information")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            VStack(spacing: 12) {
                InfoRow(label: "Email", value: supabaseManager.currentUser?.email ?? "N/A")
                InfoRow(label: "User ID", value: supabaseManager.currentUser?.id.uuidString ?? "N/A")
                InfoRow(label: "Verified", value: supabaseManager.isEmailVerified ? "Yes" : "No")
            }
            .padding(16)
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
        }
    }

    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(Color.error)

            VStack(alignment: .leading, spacing: 12) {
                Text("Delete Account")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.textPrimary)

                Text("Permanently delete your account and all associated data. This action cannot be undone.")
                    .font(.system(size: 14))
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                TextField("Why are you leaving? (optional)", text: $deleteReason)
                    .textFieldStyle(CustomTextFieldStyle())
                    .padding(.top, 8)

                Button(action: { showDeleteConfirmation = true }) {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete My Account")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.error)
                    .cornerRadius(12)
                }
                .disabled(isDeleting)
                .padding(.top, 8)

                if isDeleting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Processing deletion request...")
                            .font(.system(size: 14))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding(16)
            .background(Color.error.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.error.opacity(0.3), lineWidth: 1)
            )
        }
    }

    private func requestAccountDeletion() {
        isDeleting = true

        Task {
            do {
                // Request deletion (will be implemented in SupabaseManager)
                try await supabaseManager.requestAccountDeletion(reason: deleteReason)

                // Sign out user
                try await supabaseManager.signOut()

                await MainActor.run {
                    isDeleting = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeleting = false
                    errorMessage = "Failed to request account deletion: \(error.localizedDescription)"
                    showError = true
                }
            }
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

#Preview {
    DeleteAccountView()
}
