//
//  SynapseApp.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import Firebase

@main
struct SynapseApp: App {
    @StateObject private var localizationManager = LocalizationManager.shared
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseApp.configure()
        GoogleSignInManager.shared.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.currentUser != nil {
                    // User is signed in - show main app
                    ContentView()
                        .environmentObject(localizationManager)
                        .environmentObject(firebaseManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                } else {
                    // User is not signed in - show authentication
                    AuthenticationView()
                        .environmentObject(localizationManager)
                        .environmentObject(firebaseManager)
                        .environment(\.locale, localizationManager.locale)
                        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                }
            }
        }
    }
}
