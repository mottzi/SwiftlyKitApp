# Local Triple library

Open `TripleApp.xcworkspace` for development. Select the `TripleApp` scheme and
My Mac, then build or run normally in Xcode.

The workspace includes the app project and the sibling `../Triple` Swift package.
The local package overrides the app project's GitHub dependency. Uncommitted
library changes and newly added source files are available to the app without
publishing or changing its remote revision.

Keep the `TripleApp` and `Triple` checkout folders beside each other. The workspace
uses the library directly; no source copies, symbolic links, or Git URL rewrites
are needed.

`TripleApp.xcodeproj` retains the remote GitHub dependency for release builds.
The release export script uses that project without the workspace override.
