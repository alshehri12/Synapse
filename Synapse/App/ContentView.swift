//
//  ContentView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var firebaseManager: FirebaseManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem {
                    Image(systemName: "sparkles")
                    Text("Explore".localized)
                }
                .tag(0)
            
            MyPodsView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("My Pods".localized)
                }
                .tag(1)
            
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell")
                    Text("Notifications".localized)
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile".localized)
                }
                .tag(3)
        }
        .accentColor(Color("AccentGreen"))
        .preferredColorScheme(.light)
        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
    }
}

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(FirebaseManager.shared)
}
