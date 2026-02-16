//
//  OIDCAuthenticationManager.swift
//  CanvasPlusPlayground
//
//  Created by Auto on 2/16/26.
//

import Foundation
import AppAuth
#if os(macOS)
import AppKit
#endif
#if os(iOS)
import UIKit
#endif

@Observable
class OIDCAuthenticationManager {
    static let shared = OIDCAuthenticationManager()
    
    // OIDC Configuration
    private let clientId = "7187d5ee-0029-4e6c-b579-07320bcb0fd8"
    private let redirectURI = "canvasplus://oidc/callback"
    private let wellKnownURL = "https://sso.gatech.edu/cas/oidc/.well-known"
    
    private(set) var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private var authState: OIDAuthState?
    
    private init() {
        // Load saved auth state if available
        loadAuthState()
    }
    
    // MARK: - Public Methods
    
    /// Initiates the OIDC authentication flow
    @MainActor
    func authenticate() async throws {
        // The well-known URL should point to the issuer
        // If the URL ends with /.well-known, remove it as AppAuth will append /.well-known/openid-configuration
        var issuerURLString = wellKnownURL
        if issuerURLString.hasSuffix("/.well-known") {
            issuerURLString = String(issuerURLString.dropLast("/.well-known".count))
        }
        
        guard let issuerURL = URL(string: issuerURLString) else {
            throw OIDCAuthenticationError.invalidConfiguration("Invalid well-known URL: \(wellKnownURL)")
        }
        
        // Discover the OIDC configuration
        // AppAuth will automatically append /.well-known/openid-configuration to the issuer URL
        let configuration: OIDServiceConfiguration
        do {
            configuration = try await OIDAuthorizationService.discoverConfiguration(forIssuer: issuerURL)
        } catch {
            throw OIDCAuthenticationError.invalidConfiguration("Failed to discover configuration: \(error.localizedDescription)")
        }
        
        // Create the authorization request
        guard let redirectURL = URL(string: redirectURI) else {
            throw OIDCAuthenticationError.invalidConfiguration("Invalid redirect URI")
        }
        
        let request = OIDAuthorizationRequest(
            configuration: configuration,
            clientId: clientId,
            scopes: [OIDScopeOpenID, OIDScopeProfile],
            redirectURL: redirectURL,
            responseType: OIDResponseTypeCode,
            additionalParameters: nil
        )
        
        // Perform the authorization request
        let authState = try await performAuthorizationRequest(request)
        
        // Save the auth state
        self.authState = authState
        saveAuthState()
        
        // Store the access token
        if let accessToken = authState.lastTokenResponse?.accessToken {
            StorageKeys.accessTokenValue = accessToken
        }
    }
    
    /// Handles the OIDC callback URL
    func handleCallback(url: URL) -> Bool {
        guard let currentFlow = currentAuthorizationFlow else {
            return false
        }
        
        if currentFlow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        
        return false
    }
    
    /// Signs out the user
    func signOut() {
        authState = nil
        currentAuthorizationFlow?.cancel()
        currentAuthorizationFlow = nil
        clearAuthState()
        StorageKeys.accessTokenValue = ""
    }
    
    /// Checks if the user is authenticated
    var isAuthenticated: Bool {
        guard let authState = authState else { return false }
        return authState.isAuthorized && !StorageKeys.accessTokenValue.isEmpty
    }
    
    /// Refreshes the access token if needed
    @MainActor
    func refreshTokenIfNeeded() async throws {
        guard let authState = authState else {
            throw OIDCAuthenticationError.notAuthenticated
        }
        
        if authState.isAuthorized {
            // Check if token needs refresh (within 5 minutes of expiry)
            if let tokenResponse = authState.lastTokenResponse,
               let expiresIn = tokenResponse.accessTokenExpirationDate {
                let timeUntilExpiry = expiresIn.timeIntervalSinceNow
                if timeUntilExpiry < 300 { // 5 minutes
                    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                        authState.performAction { accessToken, idToken, error in
                            if let error = error {
                                continuation.resume(throwing: OIDCAuthenticationError.tokenRefreshFailed(error.localizedDescription))
                            } else if let accessToken = accessToken {
                                StorageKeys.accessTokenValue = accessToken
                                continuation.resume()
                            } else {
                                continuation.resume(throwing: OIDCAuthenticationError.tokenRefreshFailed("No access token received"))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    @MainActor
    private func performAuthorizationRequest(_ request: OIDAuthorizationRequest) async throws -> OIDAuthState {
        return try await withCheckedThrowingContinuation { continuation in
            #if os(iOS)
            guard let presentingViewController = getPresentingViewController() else {
                continuation.resume(throwing: OIDCAuthenticationError.noPresentingViewController)
                return
            }
            
            let userAgent = OIDExternalUserAgentIOS(presenting: presentingViewController)
            currentAuthorizationFlow = OIDAuthorizationService.present(
                request,
                externalUserAgent: userAgent!
            ) { authState, error in
                if let error = error {
                    continuation.resume(throwing: OIDCAuthenticationError.authorizationFailed(error.localizedDescription))
                } else if let authState = authState {
                    continuation.resume(returning: authState)
                } else {
                    continuation.resume(throwing: OIDCAuthenticationError.authorizationFailed("Unknown error"))
                }
            }
            #elseif os(macOS)
            // macOS implementation using ASWebAuthenticationSession
            // AppAuth for macOS uses OIDExternalUserAgentMac which wraps ASWebAuthenticationSession
            guard let presentingWindow = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first else {
                continuation.resume(throwing: OIDCAuthenticationError.noPresentingViewController)
                return
            }
            
            let userAgent = OIDExternalUserAgentMac(presenting: presentingWindow)
            currentAuthorizationFlow = OIDAuthorizationService.present(
                request,
                externalUserAgent: userAgent
            ) { authState, error in
                if let error = error {
                    continuation.resume(throwing: OIDCAuthenticationError.authorizationFailed(error.localizedDescription))
                } else if let authState = authState {
                    continuation.resume(returning: authState)
                } else {
                    continuation.resume(throwing: OIDCAuthenticationError.authorizationFailed("Unknown error"))
                }
            }
            #endif
        }
    }
    
    private func getPresentingViewController() -> UIViewController? {
        #if os(iOS)
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = window.rootViewController else {
            return nil
        }
        
        // Find the topmost view controller
        var topController = rootViewController
        while let presented = topController.presentedViewController {
            topController = presented
        }
        return topController
        #else
        return nil
        #endif
    }
    
    // MARK: - Auth State Persistence
    
    private func saveAuthState() {
        guard let authState = authState else { return }
        
        // Use NSCoding for OIDAuthState persistence
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: authState, requiringSecureCoding: false) {
            UserDefaults.standard.set(data, forKey: "OIDCAuthState")
        }
    }
    
    private func loadAuthState() {
        guard let data = UserDefaults.standard.data(forKey: "OIDCAuthState") else { return }
        
        if let authState = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? OIDAuthState {
            self.authState = authState
            // Restore access token if available
            if let accessToken = authState.lastTokenResponse?.accessToken {
                StorageKeys.accessTokenValue = accessToken
            }
        }
    }
    
    private func clearAuthState() {
        UserDefaults.standard.removeObject(forKey: "OIDCAuthState")
    }
}

// MARK: - Errors

enum OIDCAuthenticationError: LocalizedError {
    case invalidConfiguration(String)
    case authorizationFailed(String)
    case tokenExchangeFailed(String)
    case tokenRefreshFailed(String)
    case notAuthenticated
    case noPresentingViewController
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .authorizationFailed(let message):
            return "Authorization failed: \(message)"
        case .tokenExchangeFailed(let message):
            return "Token exchange failed: \(message)"
        case .tokenRefreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .notAuthenticated:
            return "User is not authenticated"
        case .noPresentingViewController:
            return "No presenting view controller available"
        }
    }
}
