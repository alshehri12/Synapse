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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if !supabaseManager.isAuthReady {
                    // Show loading while checking auth state
                    LoadingView()
                        .environmentObject(localizationManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                } else if supabaseManager.isAuthenticated && !supabaseManager.isSigningUp {
                    // User is signed in - show main app (no email verification gate per request)
                    ContentView()
                        .environmentObject(localizationManager)
                        .environmentObject(supabaseManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                } else {
                    // User is not signed in or email not verified - show authentication
                    AuthenticationView()
                        .environmentObject(localizationManager)
                        .environmentObject(supabaseManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
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
