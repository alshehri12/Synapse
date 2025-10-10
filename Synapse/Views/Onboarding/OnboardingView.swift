//
//  OnboardingView.swift
//  Synapse
//
//  Created by Claude Code
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    @EnvironmentObject private var localizationManager: LocalizationManager

    let pages: [OnboardingPage] = [
        OnboardingPage(
            imageName: "onboarding1",
            title: "Spark Your Ideas",
            description: "Transform your brilliant ideas into reality. Share, collaborate, and bring innovation to life with Synapse.",
            systemIcon: "lightbulb.fill"
        ),
        OnboardingPage(
            imageName: "onboarding2",
            title: "Collaborate & Create",
            description: "Join pods, work with talented creators, and build amazing projects together in a supportive community.",
            systemIcon: "person.3.fill"
        ),
        OnboardingPage(
            imageName: "onboarding3",
            title: "Launch Your Projects",
            description: "Take your ideas from concept to launch. Track progress, manage tasks, and celebrate success.",
            systemIcon: "rocket.fill"
        ),
        OnboardingPage(
            imageName: "onboarding4",
            title: "Safe & Secure",
            description: "Your privacy matters. We protect your data with enterprise-grade security and never share your information.",
            systemIcon: "lock.shield.fill"
        )
    ]

    var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(Color.textSecondary)
                    .padding()
                }

                // Page Content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Page Indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.accentGreen : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 20)

                // Action Buttons
                HStack(spacing: 16) {
                    if currentPage > 0 {
                        Button(action: previousPage) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundColor(Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.backgroundSecondary)
                            .cornerRadius(12)
                        }
                    }

                    Button(action: {
                        if currentPage < pages.count - 1 {
                            nextPage()
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        HStack {
                            Text(currentPage < pages.count - 1 ? "Next" : "Get Started")
                                .fontWeight(.semibold)
                            if currentPage < pages.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.accentGreen)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }

    private func nextPage() {
        withAnimation {
            currentPage += 1
        }
    }

    private func previousPage() {
        withAnimation {
            currentPage -= 1
        }
    }

    private func completeOnboarding() {
        withAnimation {
            hasCompletedOnboarding = true
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Icon
            if let systemIcon = page.systemIcon {
                ZStack {
                    Circle()
                        .fill(Color.accentGreen.opacity(0.1))
                        .frame(width: 140, height: 140)

                    Image(systemName: systemIcon)
                        .font(.system(size: 60))
                        .foregroundColor(Color.accentGreen)
                }
            }

            // Title
            Text(page.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Description
            Text(page.description)
                .font(.system(size: 17))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .padding(.horizontal, 32)

            Spacer()
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(LocalizationManager())
}
