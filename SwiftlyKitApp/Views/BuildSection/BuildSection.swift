import SwiftUI

struct BuildSection: View {

    @Environment(PackageModel.self) private var packageModel

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .foregroundStyle(.secondary)
            .frame(minHeight: 80)
            .disabled(!packageModel.isPackageSelected)
    }
    
}
