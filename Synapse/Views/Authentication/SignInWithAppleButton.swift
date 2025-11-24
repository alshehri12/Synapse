//
//  SignInWithAppleButton.swift
//  Synapse
//
//  Created by AI Assistant on 2025-01-24.
//

import SwiftUI
import AuthenticationServices

struct SignInWithAppleButton: View {
    @EnvironmentObject private var supabaseManager: SupabaseManager
    @EnvironmentObject private var localizationManager: LocalizationManager
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            isPressed = true
            handleSignInWithApple()
        }) {
            HStack(spacing: 14) {
                // Apple Logo
                Image(systemName: "apple.logo")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)

                Text(localizationManager.currentLanguage == .arabic ?
                     "تسجيل الدخول باستخدام Apple" :
                     "Continue with Apple")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 58)
            .padding(.horizontal, 20)
            .background(Color.black)
            .cornerRadius(16)
        }
        .buttonStyle(ModernScaleButtonStyle())
        .disabled(isPressed)
    }

    private func handleSignInWithApple() {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]

        let authorizationController = ASAuthorizationController(authorizationRequests: [request])

        let coordinator = AppleSignInCoordinator(
            onCompletion: { result in
                Task {
                    do {
                        switch result {
                        case .success(let authorization):
                            try await supabaseManager.signInWithApple(authorization: authorization)
                        case .failure(let error):
                            print("❌ Sign in with Apple failed: \(error.localizedDescription)")
                        }
                    } catch {
                        print("❌ Sign in with Apple error: \(error.localizedDescription)")
                    }
                    await MainActor.run {
                        isPressed = false
                    }
                }
            }
        )

        authorizationController.delegate = coordinator
        authorizationController.presentationContextProvider = coordinator

        // Keep coordinator alive
        AppleSignInCoordinator.currentCoordinator = coordinator

        authorizationController.performRequests()
    }
}

// Coordinator class for handling Apple Sign In
class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    static var currentCoordinator: AppleSignInCoordinator?

    let onCompletion: (Result<ASAuthorization, Error>) -> Void

    init(onCompletion: @escaping (Result<ASAuthorization, Error>) -> Void) {
        self.onCompletion = onCompletion
        super.init()
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first?.windows
            .first(where: { $0.isKeyWindow }) else {
            return UIWindow()
        }
        return window
    }

    func authorizationController(controller: ASAuthorizationController,
                                didCompleteWithAuthorization authorization: ASAuthorization) {
        onCompletion(.success(authorization))
        AppleSignInCoordinator.currentCoordinator = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                didCompleteWithError error: Error) {
        onCompletion(.failure(error))
        AppleSignInCoordinator.currentCoordinator = nil
    }
}
