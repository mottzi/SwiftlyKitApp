import SwiftUI

/// Guide to package selection, Linux builds, and executable export.
struct HelpView: View {

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Build a Linux executable")
                    .font(.title2.bold())

                topic(
                    "1. Select a package",
                    "Choose a folder containing Package.swift, or the Package.swift file itself. " +
                    "You can also drag either into the app. The package must declare an executable product " +
                    "and its code and dependencies must support Linux."
                )

                topic(
                    "2. Choose what to build",
                    "Select the executable product and the architecture of the Linux machine that will run it. " +
                    "Use Release for an optimized build or Debug for debugging. " +
                    "The information buttons explain each option, including how Automatic selects Swift."
                )

                topic(
                    "3. Prepare the tools",
                    "The app checks for Swift and its matching Static Linux SDK. " +
                    "If tools are missing, review the installation request. " +
                    "The request also tells you if Swiftly may need an update. " +
                    "Installation can take several minutes."
                )

                topic(
                    "4. Build",
                    "Click the blue Build button or press Command-B. " +
                    "Follow progress in Build Output. If a build fails, open its error details. " +
                    "The resulting executable runs on Linux, not on this Mac."
                )

                topic(
                    "5. Export the result",
                    "After a successful build, open the result button beside the status. " +
                    "Choose Export Build… and select a destination folder. " +
                    "The app copies the executable and its required resource bundles there. " +
                    "Keep these bundles beside the executable on Linux; static linking does not embed them. " +
                    "Show in Finder reveals the current build files."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
            .textSelection(.enabled)
        }
        .frame(minWidth: 360, minHeight: 320)
    }

}

extension HelpView {

    private func topic(_ title: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.headline)
            Text(detail)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

}
