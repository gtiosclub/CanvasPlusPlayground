# Canvas Plus
A multi-semester initiative by iOS Club @ GT, working towards a better iOS and macOS client for students using Canvas.

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

### SwiftLint

This project uses [SwiftLint](https://github.com/realm/SwiftLint), a Swift Package that ensures consistent code formatting across the codebase. Please resolve these before merging new code into the codebase.

SwiftLint can automatically fix most of these errors for you:

1. Install `swiftlint` via your Terminal: `brew install swiftlint`.
2. `swiflint lint --fix` automatically runs whenever you build or run in Xcode, which will fix most issues or throw warnings related to code formatting.

To make your life easier, you can have Xcode automatically reformat after a particular column length, and trim trailing whitespaces:

1. Open Xcode preferences (<kbd>⌘</kbd> + <kbd>,</kbd>)
2. Go to Text Editing > Editing
3. Turn on "Automatically reformat when completing code", "Automatically trim trailing whitespaces", and "Including whitespace-only lines"

### Development Team

After cloning, run these commands to set up Git filters for development team persistence:

```bash
chmod +x .git-filters/development-team
git config filter.development-team.clean ".git-filters/development-team clean"
git config filter.development-team.smudge ".git-filters/development-team smudge"
```

Then, modify your Development Team under Signing & Capabilities. Add this to the Git commit. It should now not appear on the Git log but will still persist and therefore cannot be committed.
