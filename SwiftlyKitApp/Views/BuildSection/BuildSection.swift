import SwiftUI

struct BuildSection: View {

    @Environment(BuildOptions.self) private var buildOptions

    var body: some View {
        SectionSurface()
            .frame(minHeight: Self.minimumHeight)
            .deemphasiseContent(when: !buildOptions.hasValidSelections)
    }

}

extension BuildSection {

    static let minimumHeight: CGFloat = 80

}
