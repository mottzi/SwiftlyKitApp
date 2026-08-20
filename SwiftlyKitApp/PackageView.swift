import SwiftUI

struct PackageView: View {

    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.blue)
    }

}

#Preview {
    PackageView()
        .padding()
        .frame(width: 500, height: 300)
}
