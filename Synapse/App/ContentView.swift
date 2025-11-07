//
//  ContentView.swift
//  Synapse
//
//  Created by Abdulrahman Alshehri on 18/01/1447 AH.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var localizationManager: LocalizationManager
    @EnvironmentObject private var supabaseManager: SupabaseManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExploreView()
                .tabItem {
                    Image(systemName: "lightbulb")
                    Text("Explore".localized)
                }
                .tag(0)
            
            MyPodsView()
                .tabItem {
                    Image(systemName: "person.3")
                    Text("My Projects".localized)
                }
                .tag(1)
            
            NotificationsViewRedesigned()
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
        .tint(Color.accentGreen)
        .environment(\.layoutDirection, localizationManager.currentLanguage == .arabic ? .rightToLeft : .leftToRight)
        .onReceive(NotificationCenter.default.publisher(for: .switchToMyPods)) { _ in
            selectedTab = 1
        }
        .onAppear {
            // Ensure tab bar is visible and properly configured
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            // Set tint color
            UITabBar.appearance().tintColor = UIColor(Color.accentGreen)
            UITabBar.appearance().unselectedItemTintColor = UIColor.systemGray
        }
    }
}

#if canImport(UIKit)
extension Notification.Name {
    static let switchToMyPods = Notification.Name("SwitchToMyPods")
}
#endif

#Preview {
    ContentView()
        .environmentObject(LocalizationManager.shared)
        .environmentObject(SupabaseManager.shared)
}
