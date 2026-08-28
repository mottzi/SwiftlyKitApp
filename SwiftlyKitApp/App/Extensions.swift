import SwiftUI

extension View {
    
    func debug(_ color: Color = .orange, _ width: CGFloat = 1) -> some View {
        self.border(color, width: width)
    }
    
}

extension NSPasteboard {
    
    static func copyPath(_ url: URL) {
        general.clearContents()
        general.setString(url.path(percentEncoded: false), forType: .string)
    }
    
}
