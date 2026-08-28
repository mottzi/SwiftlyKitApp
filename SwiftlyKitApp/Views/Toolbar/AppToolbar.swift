import SwiftUI

struct AppToolbar: ToolbarContent {

    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            BuildButton()
                .labelStyle(.iconOnly)
        }
    }
    
}
