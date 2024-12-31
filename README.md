# Canvas Plus (iOS)
A multi-semester iOS Club initiative, working towards a better iOS client for students using Canvas.

### Feature Database

This [feature database](https://gt-ios-club.notion.site/d2d21e2e80f3417d8528553f11a352c6?v=0b027440f1f440a3a221de8c108bf13e&pvs=4) contains a list and status of features and ideas for this project. To contribute to the list, reach out to an iOS Club exec member on our [Discord server](https://discord.gg/Kbs7zhSPex).

### Resources
- [Live API](https://gatech.instructure.com/doc/api/live#!/access_tokens.json)
- [API Docs](https://canvas.instructure.com/doc/api/assignments.html)
- [Understanding the Canvas API](https://community.canvaslms.com/t5/Canvas-Developers-Group/Canvas-APIs-Getting-started-the-practical-ins-and-outs-gotchas/ba-p/263685)

### Debugging SwiftData
- [SQLite Viewer](https://sqlitebrowser.org/blog/version-3-13-1-released/) for viewing SQLite files that SwiftData writes to.
- Print the following at app launch to get the directory storing these SQLite files.

```swift
print(URL.applicationSupportDirectory.path(percentEncoded: false))
```

### Swiftlint

This project uses [`swiftlint`](https://github.com/realm/SwiftLint), a Swift Package that ensures consistent code formatting across the codebase. Upon building the project, you will automatically see any swiftlint errors in Xcode. Please resolve these before merging new code into the codebase.

'swiftlint` can automatically fix these most of these errors for you:

1. Install swiftlint via your Terminal: `brew install swiftlint`.
2. Run `swiftlint --fix` within your project directory.

To make your life easier, you can have Xcode automatically reformat after a particular column length, and trim trailing whitespaces:

1. Open Xcode preferences (Cmd+",")
2. Go to Text Editing > Editing
3. Turn on "Automatically reformat when completing code", "Automatically trim trailing whitespaces", and "Including whitespace-only lines"


