# Sandbox Environment Implementation Guide

Step-by-step overview of how the sandbox was implemented:

---

## Overview

Goal: allow developers without Canvas API access to run the app using static dummy data and no network calls.

---

## Step 1: Global Sandbox Configuration

**File:** `Common/AppEnvironment.swift` (new)

Defined a single flag to switch between sandbox and production:

```swift
enum AppEnvironment {
    static let isSandbox = true  // Set to false for production
}
```

All sandbox behavior is driven by this flag.

---

## Step 2: Static Dummy Data

**File:** `Common/SandboxData.swift` (new)

Created static data for all course tabs and related entities:

| Data Type | Purpose |
|-----------|---------|
| `dummyCourse` | Sandbox course with all tabs (Home, Announcements, Assignments, Files, People, Grades, Quizzes, Modules, Pages, Syllabus, Groups, Calendar) |
| `dummyUser` / `dummyProfile` | Current user and profile for the app |
| `dummyAnnouncements` | One welcome announcement |
| `dummyAssignmentGroups` | Two sample assignments |
| `dummyRootFolder` / `dummyFiles` | Root folder and one sample file |
| `dummyUsers` | Two users (student and teacher) with enrollments |
| `dummyEnrollment` | Student enrollment with grade data |
| `dummyQuizzes` | One sample quiz |
| `dummyModules` / `dummyModuleItems` | One module with items |
| `dummyPages` | One welcome page |
| `dummyGroups` | One sample group |
| `dummyToDoCount` | To‑do count for the dashboard |

Course ID `12345` is used consistently across all of this data.

---

## Step 3: Manager Extensions for Sandbox Loading

**File:** `Common/Sandbox/ManagerSandboxExtensions.swift` (new)

Added extension methods that decide whether to load sandbox or real data:

- **`CourseManager.getCoursesIfNeeded()`** – Uses `dummyCourse` when in sandbox.
- **`ProfileManager.getCurrentUserAndProfileIfNeeded()`** – Uses `dummyUser` and `dummyProfile` in sandbox.
- **`ToDoListManager.fetchToDoItemCountIfNeeded()`** – Uses `dummyToDoCount` in sandbox.

These methods are used only when `AppEnvironment.isSandbox` is true.

---

## Step 4: Bypass Authentication in HomeView

**File:** `Features/Navigation/HomeView.swift`

Adjusted the `.task` so sandbox skips auth:

**Before:** Always showed auth sheet if onboarding wasn’t done or token was missing.

**After:**
```
If sandbox → load courses immediately (no auth sheet)
Else if !onboarding complete → show auth sheet
Else if needs authorization → show auth sheet  
Else → load courses normally
```

Updated `loadCourses()` to use the sandbox extensions when in sandbox:

```
If sandbox:
  - getSandboxedCourses()
  - getSandboxedCurrentUserAndProfile()
  - fetchSandboxedToDoItemCountIfNeeded()
Else:
  - Existing network-based loading (getCourses, getCurrentUserAndProfile, etc.)
```

---

## Step 5: Sandbox Checks in Feature Managers

For each feature manager that fetches from the network, an early sandbox check was added so no API calls happen in sandbox:

| Manager | Location of Check | Sandbox Behavior |
|---------|-------------------|------------------|
| `CourseAnnouncementManager` | Start of `fetchAnnouncements()` | Loads `dummyAnnouncements` |
| `CourseAssignmentManager` | Start of `fetchAssignmentGroups()` | Loads `dummyAssignmentGroups` |
| `CourseFileViewModel` | Start of `fetchRoot()` and `fetchContent()` | Loads `dummyRootFolder`, `dummyFiles` |
| `PeopleManager` | Start of `fetchPeople()` | Loads `dummyUsers` |
| `GradesViewModel` | Start of `getEnrollments()` | Loads `dummyEnrollment` |
| `QuizzesViewModel` | Start of `fetchQuizzes()` | Loads `dummyQuizzes` |
| `ModulesViewModel` | Start of `fetchModules()` | Loads `dummyModules`, `dummyModuleItems` |
| `PagesManager` | Start of `fetchPages()` | Loads `dummyPages` |
| `CourseGroupsViewModel` | Start of `fetchGroups()` | Loads `dummyGroups` |

Pattern in each:

```swift
func fetchX() async {
    if AppEnvironment.isSandbox {
        // Set data from SandboxData, return immediately
        return
    }
    // Original network-fetch logic
}
```

---

## Step 6: ProfileManager Setter for Sandbox

**File:** `Features/Profile/ProfileManager.swift`

`currentUser` and `currentProfile` use `private(set)`, so they can’t be set from extensions. Added an internal method:

```swift
func setSandboxUserAndProfile(user: User, profile: Profile) {
    currentUser = user
    currentProfile = profile
}
```

`getCurrentUserAndProfileIfNeeded()` calls this when in sandbox instead of assigning directly.

---

## Step 7: Tab Configuration for the Dummy Course

**File:** `Common/SandboxData.swift` (extension on `TabAPI`)

Extended `TabAPI` with `sandboxTabs` so the dummy course shows the same tabs as a normal course. Each tab (Home, Announcements, Assignments, Files, People, Grades, Quizzes, Modules, Pages, Syllabus, Groups, Calendar) is defined with the right IDs and labels.

`dummyCourse` wires these tabs to the course so the sidebar and navigation behave correctly.

---

## Data Flow When Sandbox Is On

1. App launches → `HomeView` appears.
2. `.task` sees `AppEnvironment.isSandbox == true` → skips auth and calls `loadCourses()`.
3. `loadCourses()` calls `getSandboxedCourses()`, `getSandboxedCurrentUserAndProfile()`, `fetchSandboxedToDoItemCount()`.
4. Those methods see sandbox → load data from `SandboxData` only, no API calls.
5. `HomeView` shows the sandbox course in the sidebar.
6. When a tab is opened (e.g., Announcements), the view calls its manager’s fetch (e.g., `fetchAnnouncements()`).
7. Each manager checks `AppEnvironment.isSandbox` at the start → uses `SandboxData` and returns without hitting the network.

---

## Switching to Production

Set sandbox to off in `Common/AppEnvironment.swift`:

```swift
static let isSandbox = false
```

After that, the app uses the normal auth flow and all network requests.

