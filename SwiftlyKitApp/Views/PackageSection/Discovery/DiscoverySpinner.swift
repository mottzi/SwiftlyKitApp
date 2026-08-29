import SwiftUI

/// Indeterminate circular progress that remains SwiftUI-native under page transforms.
struct DiscoverySpinner: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isRotating = false

    let accessibilityLabel: String

    var body: some View {
        Circle()
            .trim(from: 0.15, to: 0.85)
            .stroke(
                .secondary,
                style: StrokeStyle(
                    lineWidth: Self.lineWidth,
                    lineCap: .round
                )
            )
            .frame(width: Self.length, height: Self.length)
            .rotationEffect(.degrees(isRotating ? 360 : 0))
            .animation(spinnerAnimation, value: isRotating)
            .onAppear {
                isRotating = !reduceMotion
            }
            .onChange(of: reduceMotion) {
                isRotating = !reduceMotion
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel)
            .accessibilityValue("In progress")
            .help(accessibilityLabel)
    }

    private var spinnerAnimation: Animation? {
        guard !reduceMotion else { return nil }

        return .linear(duration: Self.duration)
            .repeatForever(autoreverses: false)
    }

}

extension DiscoverySpinner {

    private static let length: CGFloat = 10
    private static let lineWidth: CGFloat = 1.5
    private static let duration = 0.8

}
