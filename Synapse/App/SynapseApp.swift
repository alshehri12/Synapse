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
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.isAuthReady {
                    if firebaseManager.currentUser != nil {
                        ContentView()
                            .environmentObject(localizationManager)
                            .environmentObject(firebaseManager)
                            .environment(\.locale, localizationManager.locale)
                            .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                    } else {
                        AuthenticationView()
                            .environmentObject(localizationManager)
                            .environmentObject(firebaseManager)
                            .environment(\.locale, localizationManager.locale)
                            .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
                    }
                } else {
                    // Loading state
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentGreen))
                            .scaleEffect(1.2)
                        Text("Loading...".localized)
                            .font(.system(size: 16))
                            .foregroundColor(Color.textSecondary)
                            .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.backgroundSecondary)
                }
            }
        }
    }
}
