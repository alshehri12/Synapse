//
//  ModerationTestView.swift
//  Synapse
//
//  Test view to verify content moderation is working
//

import SwiftUI

struct ModerationTestView: View {
    @State private var testContent = "This is a safe message for testing"
    @State private var testResult = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                
                // Header
                VStack {
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 50))
                        .foregroundColor(.blue)
                    
                    Text("Content Moderation Test")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                
                Divider()
                
                // Test Input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Test Content:")
                        .font(.headline)
                    
                    TextEditor(text: $testContent)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                // Test Buttons
                VStack(spacing: 12) {
                    Button(action: testBasicContent) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "checkmark.shield")
                            }
                            Text("Test Current Content")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)

                    Button(action: testConnection) {
                        HStack {
                            Image(systemName: "wifi")
                            Text("Test API Connection")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(isLoading)

                    // Example test buttons
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Quick Tests:")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            Button("Safe Text") {
                                testContent = "I have a great idea for a mobile app"
                                testBasicContent()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isLoading)

                            Button("Spam Test") {
                                testContent = "BUY NOW!!! 🔥🔥🔥 CLICK HERE $$$ CHEAP!!!"
                                testBasicContent()
                            }
                            .buttonStyle(.bordered)
                            .disabled(isLoading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                
                Divider()
                
                // Results
                VStack(alignment: .leading, spacing: 10) {
                    Text("Results:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(testResult.isEmpty ? "No tests run yet" : testResult)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Moderation Test")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func testBasicContent() {
        guard !testContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            testResult = "❌ Please enter some content to test"
            return
        }
        
        isLoading = true
        testResult = "🔄 Testing content moderation..."
        
        Task {
            do {
                let result = try await ModerationService.shared.moderateContent(
                    testContent, 
                    contentType: .comment
                )
                
                await MainActor.run {
                    testResult = formatModerationResult(result)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    testResult = "❌ Error testing content: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }
    
    private func testConnection() {
        isLoading = true
        testResult = "🔄 Testing moderation services..."
        
        Task {
            let results = await ModerationService.shared.testServices()
            
            await MainActor.run {
                testResult = results.joined(separator: "\n")
                isLoading = false
            }
        }
    }
    
    private func formatModerationResult(_ result: ModerationResult) -> String {
        var output = ""
        
        // Status
        if result.isAllowed {
            output += "✅ CONTENT APPROVED\n\n"
        } else {
            output += "❌ CONTENT REJECTED\n\n"
        }
        
        // Confidence Score
        output += "📊 Confidence Score: \(String(format: "%.2f", result.confidence))\n\n"
        
        // Violations
        if result.violations.isEmpty {
            output += "🟢 No violations detected\n\n"
        } else {
            output += "⚠️ Violations detected:\n"
            for violation in result.violations {
                output += "  • \(violation.rawValue.capitalized)\n"
            }
            output += "\n"
        }
        
        // Sanitized Content
        if let sanitized = result.sanitizedContent {
            output += "🔧 Sanitized version:\n\"\(sanitized)\"\n\n"
        }
        
        return output
    }
}

#Preview {
    ModerationTestView()
}
