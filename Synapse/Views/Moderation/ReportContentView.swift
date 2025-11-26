//
//  ReportContentView.swift
//  Synapse
//
//  Content reporting interface for App Store compliance
//

import SwiftUI

struct ReportContentView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localizationManager: LocalizationManager
    @StateObject private var moderationManager = ContentModerationManager.shared

    let contentId: String
    let contentType: String
    let reportedUserId: String

    @State private var selectedReason: ReportReason = .spam
    @State private var description = ""
    @State private var isSubmitting = false
    @State private var showingSuccess = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 48))
                                .foregroundColor(Color.error)
                                .frame(maxWidth: .infinity)
                                .padding(.top, 20)

                            Text("Report Content")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(Color.textPrimary)
                                .frame(maxWidth: .infinity)

                            Text("Help us keep Synapse safe and respectful")
                                .font(.system(size: 14))
                                .foregroundColor(Color.textSecondary)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.bottom, 8)

                        // Reason Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Reason for Report")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)

                            ForEach(ReportReason.allCases, id: \.self) { reason in
                                Button(action: {
                                    selectedReason = reason
                                }) {
                                    HStack {
                                        Image(systemName: selectedReason == reason ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(selectedReason == reason ? Color.accentGreen : Color.textSecondary)

                                        Text(reason.rawValue)
                                            .font(.system(size: 15))
                                            .foregroundColor(Color.textPrimary)

                                        Spacer()
                                    }
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(selectedReason == reason ? Color.accentGreen.opacity(0.1) : Color.backgroundPrimary)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedReason == reason ? Color.accentGreen : Color.clear, lineWidth: 2)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }

                        // Additional Details
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Additional Details (Optional)")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.textPrimary)

                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.backgroundPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.textSecondary.opacity(0.2), lineWidth: 1)
                                )
                        }

                        // Info Box
                        VStack(alignment: .leading, spacing: 8) {
                            Label("What happens next?", systemImage: "info.circle")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.accentBlue)

                            Text("Our moderation team will review this report within 24 hours. If we find a violation, we'll take appropriate action including removing content or suspending accounts.")
                                .font(.system(size: 13))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding()
                        .background(Color.accentBlue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(20)
                }

                // Submit Button
                VStack(spacing: 12) {
                    Button(action: submitReport) {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        } else {
                            Text("Submit Report")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                        }
                    }
                    .background(Color.error)
                    .cornerRadius(12)
                    .disabled(isSubmitting)
                }
                .padding(20)
                .background(Color.backgroundSecondary)
            }
            .background(Color.backgroundSecondary)
            .navigationTitle("Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Report Submitted", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thank you for helping keep Synapse safe. We'll review this report within 24 hours.")
            }
        }
    }

    private func submitReport() {
        isSubmitting = true

        Task {
            do {
                try await moderationManager.reportContent(
                    contentId: contentId,
                    contentType: contentType,
                    reportedUserId: reportedUserId,
                    reason: selectedReason,
                    description: description.isEmpty ? nil : description
                )

                await MainActor.run {
                    isSubmitting = false
                    showingSuccess = true
                }
            } catch {
                print("❌ Error submitting report: \(error)")
                await MainActor.run {
                    isSubmitting = false
                }
            }
        }
    }
}
