import SwiftUI

extension View {
    
    func debug(_ color: Color = .orange, _ width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
    
}

extension NSPasteboard {
    
    func setURL(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path(percentEncoded: false), forType: .string)
    }
    
}
