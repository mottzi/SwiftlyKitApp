# Local Triple library

`TripleApp.xcworkspace` uses `Triple/` to override the project's remote Triple
dependency. Open the workspace for development and select the `TripleApp` scheme.

`Triple/` is a real directory containing relative symbolic links to the manifest,
sources, and tests in `../../SwiftlyKit`. Editing them in Xcode edits the existing
library checkout. Uncommitted changes and newly added source files are available
to the app without publishing or changing its remote revision.

Xcode requires an override directory named `Triple` to match the GitHub package
identity. A symbolic link to the whole checkout does not work because Xcode uses
the resolved directory name, `SwiftlyKit`. Linking the contents keeps the package
directory named `Triple` while using the original library files.

The library checkout must remain beside the app checkout. If you move it, update
the three links in `Triple/` to its new location. Do not replace these links with
copies of the library.

`TripleApp.xcodeproj` retains the remote GitHub dependency for release builds.
The release export script uses that project, without the workspace override.
