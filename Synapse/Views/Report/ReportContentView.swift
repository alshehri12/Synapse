//
//  ReportContentView.swift
//  Synapse
//
//  Created by Claude Code
//

import SwiftUI

struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var supabaseManager: SupabaseManager

    let contentType: ContentReport.ReportContentType
    let contentId: String
    let reportedUserId: String?

    @State private var selectedReason: ContentReport.ReportReason = .spam
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showSuccess = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Reason Selection
                    reasonSection

                    // Description
                    descriptionSection

                    // Submit Button
                    submitButton
                }
                .padding(24)
            }
            .background(Color.backgroundPrimary)
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep Synapse safe. We'll review this report shortly.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.accentGreen)

            Text("Report \(contentType.rawValue.capitalized)")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Text("Help us maintain a safe and respectful community")
                .font(.system(size: 14))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 8)
    }

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why are you reporting this?")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            VStack(spacing: 8) {
                ForEach(ContentReport.ReportReason.allCases, id: \.self) { reason in
                    ReasonButton(
                        reason: reason,
                        isSelected: selectedReason == reason,
                        action: { selectedReason = reason }
                    )
                }
            }
        }
    }

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Additional Details (Optional)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color.textPrimary)

            TextEditor(text: $description)
                .frame(height: 120)
                .padding(12)
                .background(Color.backgroundSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.border, lineWidth: 1)
                )

            Text("Provide any additional context that might help us understand the issue")
                .font(.system(size: 12))
                .foregroundColor(Color.textSecondary)
        }
    }

    private var submitButton: some View {
        Button(action: submitReport) {
            HStack {
                if isSubmitting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "paperplane.fill")
                    Text("Submit Report")
                        .fontWeight(.semibold)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.accentGreen)
            .cornerRadius(12)
        }
        .disabled(isSubmitting)
    }

    private func submitReport() {
        isSubmitting = true

        Task {
            do {
                try await supabaseManager.submitContentReport(
                    contentType: contentType,
                    contentId: contentId,
                    reportedUserId: reportedUserId,
                    reason: selectedReason,
                    description: description.isEmpty ? nil : description
                )

                await MainActor.run {
                    isSubmitting = false
                    showSuccess = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showError = true
                }
            }
        }
    }
}

struct ReasonButton: View {
    let reason: ContentReport.ReportReason
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? Color.accentGreen : Color.textSecondary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(reason.displayName)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color.textPrimary)
                }

                Spacer()
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentGreen.opacity(0.1) : Color.backgroundSecondary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentGreen : Color.border, lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    ReportContentView(
        contentType: .idea,
        contentId: "test-id",
        reportedUserId: "user-id"
    )
}
