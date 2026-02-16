# OIDC SSO Setup Instructions

This document provides instructions for completing the OIDC SSO authentication setup.

## 1. Add AppAuth Package Dependency

The OIDC authentication flow requires the AppAuth library. Add it to your Xcode project:

1. Open your project in Xcode
2. Select your project in the navigator
3. Go to the "Package Dependencies" tab
4. Click the "+" button
5. Enter the AppAuth repository URL: `https://github.com/openid/AppAuth-iOS.git`
6. Select version `1.7.0` or later
7. Click "Add Package"
8. Make sure the `AppAuth` product is added to your target

Alternatively, you can add it via the project file:
- The package reference should be added to `packageReferences` in `project.pbxproj`
- The product dependency should be added to `packageProductDependencies` in the target

## 2. Add OIDCAuthenticationManager.swift to Xcode Project

The `OIDCAuthenticationManager.swift` file has been created but needs to be added to your Xcode project:

1. In Xcode, right-click on the `Common` folder in the Project Navigator
2. Select "Add Files to CanvasPlusPlayground..."
3. Navigate to `CanvasPlusPlayground/Common/Authentication/`
4. Select `OIDCAuthenticationManager.swift`
5. Make sure "Copy items if needed" is unchecked (file is already in the project directory)
6. Make sure your target is checked
7. Click "Add"

Alternatively, Xcode may automatically detect the new file. If you see a prompt, click "Add to Project".

## 3. Verify Info.plist Configuration

The `Info.plist` has been updated with the callback URL scheme. Verify that it includes:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>canvasplus</string>
        </array>
        <key>CFBundleURLName</key>
        <string>com.canvasPlus.oidc</string>
    </dict>
</array>
```

## 4. Configuration Details

The OIDC authentication is configured with:
- **Client ID**: `7187d5ee-0029-4e6c-b579-07320bcb0fd8`
- **Callback URL**: `canvasplus://oidc/callback`
- **Well-known URL**: `https://sso.gatech.edu/cas/oidc/.well-known`
- **Scopes**: `openid profile`

## 5. Testing

1. Build and run the app
2. When prompted for authentication, tap "Sign in with Georgia Tech"
3. Complete the OAuth flow in the browser
4. The app should receive the callback and store the access token
5. Verify that the token is stored in the keychain via `StorageKeys.accessTokenValue`

## 6. Integration Points

The OIDC authentication integrates with:
- **StorageKeys**: Access tokens are stored using `StorageKeys.accessTokenValue`
- **SetupView**: Updated to show OIDC SSO button alongside manual token entry
- **HomeView**: Authentication state is checked on app launch
- **CanvasPlusPlaygroundApp**: Handles OIDC callback URLs via `onOpenURL`

## Troubleshooting

- **Build errors**: Make sure AppAuth package is added and linked to your target
- **Callback not working**: Verify Info.plist has the correct URL scheme
- **Authentication fails**: Check that the well-known URL is accessible and returns valid OIDC configuration
- **Token not stored**: Verify that StorageKeys integration is working correctly
