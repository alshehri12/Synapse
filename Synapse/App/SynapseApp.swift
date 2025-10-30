//
//  SynapseApp.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//  Updated for Supabase migration on 16/01/2025
//

import SwiftUI
import Supabase

@main
struct SynapseApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    @StateObject private var appearanceManager = AppearanceManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    // Show onboarding first
                    OnboardingView()
                        .environmentObject(localizationManager)
                        .environmentObject(appearanceManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                        .preferredColorScheme(appearanceManager.colorScheme)
                } else if !supabaseManager.isAuthReady {
                    // Show loading while checking auth state
                    LoadingView()
                        .environmentObject(localizationManager)
                        .environmentObject(appearanceManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                        .preferredColorScheme(appearanceManager.colorScheme)
                } else if supabaseManager.isAuthenticated && supabaseManager.isEmailVerified && !supabaseManager.isSigningUp {
                    // User is signed in AND email verified - show main app
                    ContentView()
                        .environmentObject(localizationManager)
                        .environmentObject(supabaseManager)
                        .environmentObject(appearanceManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                        .preferredColorScheme(appearanceManager.colorScheme)
                } else if supabaseManager.isAuthenticated && !supabaseManager.isEmailVerified {
                    // User is signed in BUT email NOT verified - show verification required screen
                    EmailVerificationRequiredView()
                        .environmentObject(localizationManager)
                        .environmentObject(supabaseManager)
                        .environmentObject(appearanceManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                        .preferredColorScheme(appearanceManager.colorScheme)
                } else {
                    // User is not signed in - show authentication
                    AuthenticationView()
                        .environmentObject(localizationManager)
                        .environmentObject(supabaseManager)
                        .environmentObject(appearanceManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                        .preferredColorScheme(appearanceManager.colorScheme)
                }
            }
        }
    }
}

// Simple loading view for auth state check
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .foregroundColor(.secondary)
                .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundSecondary)
    }
}
