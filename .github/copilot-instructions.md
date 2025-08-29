# Canvas Plus (iOS) - Development Instructions

**Always reference these instructions first and fallback to search or additional context gathering only when you encounter unexpected information that does not match the info here.**

## Project Overview

Canvas Plus is a SwiftUI-based iOS and macOS application that provides an enhanced Canvas LMS client for students. The project uses SwiftData for local storage, integrates with the Canvas API (gatech.instructure.com), and includes features for assignments, grades, announcements, courses, and more.

## Critical Build and Environment Requirements

**IMPORTANT**: This is an iOS/macOS application that **requires Xcode to build and run**. The project cannot be built on Linux or with Swift Package Manager alone.

- **Platform**: iOS 17.0+, macOS 14.0+ 
- **Xcode**: Required for building, running, and debugging
- **Swift**: 6.1+ (built with SwiftUI and SwiftData frameworks)
- **Bundle ID**: com.gtiosclub.CanvasPlus

## Initial Setup (Required After Fresh Clone)

Run these commands immediately after cloning:

```bash
# Set up Git filters for development team management (prevents DEVELOPMENT_TEAM commits)
chmod +x .git-filters/development-team
git config filter.development-team.clean ".git-filters/development-team clean"
git config filter.development-team.smudge ".git-filters/development-team smudge"
```

**Note**: The git filter automatically strips development team IDs from project.pbxproj to prevent them from appearing in commits, but preserves them locally for building.

## Code Quality and Linting

### SwiftLint Setup and Usage

SwiftLint is **required** and configured via `.swiftlint.yml`. All code changes must pass SwiftLint validation.

#### Installing SwiftLint:
```bash
# macOS (recommended):
brew install swiftlint

# Linux (for validation only, cannot build the app):
curl -fsSL https://github.com/realm/SwiftLint/releases/download/0.57.0/swiftlint_linux.zip -o /tmp/swiftlint.zip
cd /tmp && unzip swiftlint.zip && sudo mv swiftlint /usr/local/bin/ && chmod +x /usr/local/bin/swiftlint
```

#### SwiftLint Commands:
```bash
# Check for violations (takes ~1 second):
swiftlint lint --quiet

# Auto-fix violations (takes ~2 seconds):
swiftlint --fix --quiet

# Generate detailed report:
swiftlint lint --reporter emoji
```

**CRITICAL**: Always run `swiftlint --fix` before committing changes. SwiftLint violations will cause CI failures.

**Note**: SwiftLint --fix will automatically modify files to fix violations and these changes should be committed.

### SwiftLint Configuration Highlights:
- Line length limit: 150 characters (warning), 200 characters (error)
- Function body length: 60 lines (warning), 80 lines (error) 
- Custom rules include: no commented code, no direct print statements, SwiftUI state privacy
- 60+ opt-in rules enabled for code quality

## Building and Running

### Xcode Build Process:
```bash
# Build the project (requires macOS with Xcode installed):
xcodebuild -project CanvasPlusPlayground.xcodeproj -scheme CanvasPlusPlayground -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build for macOS:
xcodebuild -project CanvasPlusPlayground.xcodeproj -scheme CanvasPlusPlayground -destination 'platform=macOS' build
```

**NEVER CANCEL BUILDS**: Xcode builds can take 5-15 minutes depending on system. Set timeout to 30+ minutes.

**LINUX LIMITATION**: xcodebuild is not available on Linux. Building and running requires macOS with Xcode installed.

### Running the Application:
- **iOS**: Use Xcode's iOS Simulator or physical device
- **macOS**: Run directly on macOS (supports both iOS and macOS via Mac Catalyst)
- **Linux**: Cannot run the application (iOS/macOS frameworks not available)

## Testing and Validation

### Manual Validation Required:
After making changes, always test these core workflows:

1. **Launch and Navigation**: App launches successfully, main navigation works
2. **Course Loading**: Courses load from Canvas API 
3. **Assignment Views**: Assignment lists and details display correctly
4. **Settings**: Access token management works
5. **SwiftData Storage**: Local data persistence functions

### No Automated Tests:
This project currently has no unit tests or UI tests. Validation must be done manually through the running application.

## Project Structure and Navigation

### Key Directories:
```
CanvasPlusPlayground/
├── CanvasPlusPlaygroundApp.swift          # App entry point and setup
├── Common/                                # Shared utilities and components
│   ├── Components/                        # Reusable SwiftUI components
│   ├── Network/                          # Canvas API networking layer
│   ├── Storage/                          # SwiftData model container setup
│   └── Utilities/                        # Helper classes and extensions
├── Features/                             # Feature-based organization (21 features)
│   ├── Assignments/                      # Assignment management
│   ├── Courses/                          # Course listing and details
│   ├── Grades/                           # Grade viewing and calculations
│   ├── Navigation/                       # App navigation and HomeView
│   ├── Profile/                          # User profile management
│   ├── Settings/                         # App settings and configuration
│   └── [16 other feature directories]
└── Intelligence/                         # AI/ML features (iOS 18+ only)
```

### Important Entry Points:
- **App Root**: `CanvasPlusPlaygroundApp.swift` - App lifecycle and dependency injection
- **Main UI**: `Features/Navigation/HomeView.swift` - Primary app interface
- **API Layer**: `Common/Network/CanvasService.swift` - Canvas API integration
- **Data Models**: Each feature has its own `Models/` subdirectory

### Most Frequently Modified Files:
When making changes, these files are commonly touched:
- Assignment features: `Features/Assignments/`
- Course management: `Features/Courses/CourseManager.swift`
- API requests: `Common/Network/API Requests/`
- Navigation: `Features/Navigation/NavigationModel.swift`

## Canvas API Integration

### API Configuration:
- **Base URL**: `https://gatech.instructure.com/`
- **Authentication**: Access token-based (managed in Settings)
- **Deep Linking**: Supports `canvas-courses://` URL scheme

### Key API Classes:
- `CanvasService`: Main API service singleton
- `CanvasRepository`: SwiftData persistence layer  
- `APIRequest` protocols: Type-safe request definitions

## Development Workflow

### Before Making Changes:
1. Run `swiftlint lint` to check current state
2. Set up git filters if not already configured
3. Open project in Xcode for building/testing

### During Development:
1. Make minimal, focused changes
2. Run `swiftlint --fix` frequently
3. Test changes in iOS Simulator
4. Verify SwiftData storage if touching data models

### Before Committing:
```bash
# REQUIRED: Fix all SwiftLint violations
swiftlint --fix --quiet

# Verify no new violations:
swiftlint lint --quiet

# Check git status (development team should not appear):
git status
git diff
```

## Debugging and Troubleshooting

### SwiftData Debugging:
```swift
// Print SwiftData storage location:
print(URL.applicationSupportDirectory.path(percentEncoded: false))
```
Use [SQLite Viewer](https://sqlitebrowser.org/) to inspect SwiftData SQLite files.

### Common Issues:
- **Build Failures**: Usually SwiftLint violations or missing dependencies
- **Canvas API Errors**: Check access token in Settings
- **SwiftData Issues**: Try clearing local storage via Settings > Debug > Clear Cache

### Debug Settings Available:
In debug builds, Settings includes:
- Clear Cache (SwiftData reset)
- Clear All Files 
- View Item Picker
- Show Files in Finder (macOS only)

## Key Dependencies and Frameworks

### Apple Frameworks:
- SwiftUI (UI framework)
- SwiftData (data persistence) 
- Foundation (core utilities)
- UserNotifications (reminders)

### External Dependencies:
- SwiftLint (code quality, not a runtime dependency)

## Performance and Timing

### Expected Command Times:
- SwiftLint lint: ~1 second
- SwiftLint fix: ~2 seconds  
- Xcode build (clean): 10-15 minutes - **NEVER CANCEL**
- Xcode build (incremental): 1-3 minutes

### File Statistics:
- Total Swift files: 217
- Features: 21 distinct feature areas
- Lines of code: ~15,000+ lines

## Contributing Guidelines

### Code Style:
- Follow SwiftLint rules (automatically enforced)
- Use feature-based organization for new code
- Prefer SwiftUI over UIKit
- Use SwiftData for persistence

### Pull Request Requirements:
- All SwiftLint violations resolved
- Manual testing completed
- Changes work on both iOS and macOS (when applicable)
- No commented-out code committed

**Remember: Always validate your changes by building and running the app in Xcode. SwiftLint validation alone is not sufficient.**