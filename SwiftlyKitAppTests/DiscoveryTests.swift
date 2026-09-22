import AppKit
@testable import SwiftlyKit
import SwiftUI
import Testing
@testable import SwiftlyKitApp

@Suite(.serialized)
struct DiscoveryTests {

    @MainActor
    @Test("Installation failures use the existing product retry action")
    func installationFailureStatus() {

        let status = BuildSetupStatus.current(
            host: .ready,
            toolchain: .ready([.automatic]),
            product: .failed(.swiftlyInstallationFailed("Installing Swift 6.4.0 failed.\nLock held by process 52499"))
        )
        #expect(status.title == "Tool installation failed")
        #expect(status.detail == "Installing Swift 6.4.0 failed.\nLock held by process 52499")
        #expect(status.action == .productDetails)
    }

    @MainActor
    @Test("Installation approval discloses conditional updates to existing Swiftly")
    func approvalIncludesSwiftlyUpdate() {

        let request = InstallationApprovalRequest(
            swiftVersion: SwiftVersion(major: 6, minor: 4, patch: 0),
            staticLinuxSDKVersion: "0.1.0",
            requiredComponents: [.swiftlyUpdate, .toolchain, .staticLinuxSDK]
        )
        #expect(
            request.message == "Update your existing Swiftly installation if needed, then install "
                + "Swift 6.4.0 and Static Linux SDK 0.1.0?"
        )
    }

    @MainActor
    @Test
    func discoverySpinnerDoesNotHostAnAppKitProgressIndicator() async {
        let hostingView = NSHostingView(
            rootView: AnyView(
                DiscoverySpinner(accessibilityLabel: "Discovering")
            )
        )
        hostingView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

        hostingView.layoutSubtreeIfNeeded()
        await Task.yield()
        hostingView.layoutSubtreeIfNeeded()

        let appKitProgressViews = descendantViews(of: hostingView).filter { view in
            view is NSProgressIndicator
                || String(reflecting: type(of: view)).contains("AppKitProgressView")
        }

        #expect(
            appKitProgressViews.isEmpty,
            "Discovery must not add an AppKit progress indicator under the animated page scale."
        )

        hostingView.rootView = AnyView(EmptyView())
        await Task.yield()
    }

    @MainActor
    @Test
    func exactToolchainSelectionSurvivesOnlyWhileCompatible() {
        let selectedVersion = SwiftVersion(major: 6, minor: 3, patch: 1)
        let otherVersion = SwiftVersion(major: 6, minor: 2, patch: 0)
        let selected = ToolchainSelection.exact(selectedVersion)

        #expect(
            ToolchainDiscovery.reconciledToolchain(selected, available: [
                .exact(selectedVersion),
                .exact(otherVersion)
            ]) == selected
        )
        #expect(
            ToolchainDiscovery.reconciledToolchain(
                selected,
                available: [.exact(otherVersion)]
            ) == .automatic
        )
        #expect(
            ToolchainDiscovery.reconciledToolchain(
                .automatic,
                available: [.exact(selectedVersion)]
            ) == .automatic
        )
    }

    @MainActor
    @Test("Offline discovery preserves an explicit version absent from the installed choices")
    func offlineDiscoveryPreservesExactSelection() {
        let selected = ToolchainSelection.exact(SwiftVersion(major: 6, minor: 4, patch: 0))
        let installed = ToolchainSelection.exact(SwiftVersion(major: 6, minor: 3, patch: 3))

        #expect(ToolchainDiscovery.reconciledToolchain(
            selected,
            available: [installed],
            usesCachedCatalog: true
        ) == selected)
        #expect(ToolchainDiscovery.reconciledToolchain(
            .automatic,
            available: [installed],
            usesCachedCatalog: true
        ) == .automatic)
    }

    @MainActor
    @Test
    func installationApprovalDescribesTheCompletePreparationPlan() {
        let request = InstallationApprovalRequest(
            swiftVersion: SwiftVersion(major: 6, minor: 3, patch: 2),
            staticLinuxSDKVersion: "0.1.0",
            requiredComponents: [.swiftly, .toolchain, .staticLinuxSDK]
        )

        #expect(
            request.message == "Do you want to install Swiftly, Swift 6.3.2, "
                + "and Static Linux SDK 0.1.0?"
        )
    }

    @MainActor
    @Test
    func installationApprovalAdaptsToOneMissingComponent() {
        let request = InstallationApprovalRequest(
            swiftVersion: SwiftVersion(major: 6, minor: 2, patch: 1),
            staticLinuxSDKVersion: "0.1.0",
            requiredComponents: [.staticLinuxSDK]
        )

        #expect(
            request.message == "Do you want to install Static Linux SDK 0.1.0?"
        )
    }

    @MainActor
    @Test
    func productRediscoveryPreservesTheSelectedProductByName() {

        let discovery = BuildOptions().productDiscovery
        let firstProduct = ExecutableProduct(name: "FirstProduct")
        let selectedProduct = ExecutableProduct(name: "SelectedProduct")
        discovery.replaceProducts(with: [firstProduct, selectedProduct])
        discovery.selectedProduct = selectedProduct
        discovery.invalidate()

        let replacement = ExecutableProduct(name: "SelectedProduct")
        discovery.replaceProducts(with: [firstProduct, replacement])

        #expect(discovery.selectedProduct == replacement)
        #expect(discovery.availableProducts == [firstProduct, replacement])
        #expect(discovery.state == .ready)
    }

    @MainActor
    @Test
    func clearingProductsResetsTheSelectionBeforeTheNextDiscovery() {

        let discovery = BuildOptions().productDiscovery
        let firstProduct = ExecutableProduct(name: "FirstProduct")
        let selectedProduct = ExecutableProduct(name: "SelectedProduct")
        discovery.replaceProducts(with: [firstProduct, selectedProduct])
        discovery.selectedProduct = selectedProduct

        discovery.clear()

        #expect(discovery.selectedProduct == nil)
        #expect(discovery.availableProducts.isEmpty)
        #expect(discovery.state == .idle)

        discovery.replaceProducts(with: [firstProduct, selectedProduct])

        #expect(discovery.selectedProduct == firstProduct)
    }

    @MainActor
    @Test
    func productRediscoveryKeepsTheOldSelectionUntilReplacementArrives() {
        let discovery = BuildOptions().productDiscovery
        let oldProduct = ExecutableProduct(name: "OldProduct")
        let firstReplacement = ExecutableProduct(name: "FirstReplacement")
        let secondReplacement = ExecutableProduct(name: "SecondReplacement")

        discovery.replaceProducts(with: [oldProduct])
        discovery.invalidate()

        #expect(discovery.selectedProduct == oldProduct)
        #expect(discovery.availableProducts == [oldProduct])

        discovery.replaceProducts(with: [firstReplacement, secondReplacement])

        #expect(discovery.selectedProduct == firstReplacement)
        #expect(discovery.availableProducts == [firstReplacement, secondReplacement])
    }

}
