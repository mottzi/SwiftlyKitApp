import SwiftUI

@main
struct SwiftlyKitApp: App {

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 700, height: 500)
        .windowToolbarStyle(.unified(showsTitle: true))
    }
    
}
