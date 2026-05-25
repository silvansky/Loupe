import Foundation
import Testing
@testable import LoupeCore

struct SnapshotQueryTests {
    @Test func findByTestIDPrefersInteractiveResultOrder() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                testID: "checkout.payButton",
                text: "Pay now",
                frame: LoupeRect(x: 24, y: 100, width: 120, height: 30),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
            LoupeNode(
                ref: "n2",
                parentRef: nil,
                kind: .view,
                typeName: "UIButton",
                role: "button",
                testID: "checkout.payButton",
                text: "Pay now",
                frame: LoupeRect(x: 24, y: 200, width: 200, height: 52),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.testID("checkout.payButton"), in: snapshot)

        #expect(results.map { $0.ref } == ["n2", "n1"])
    }

    @Test func findByTextCanUsePartialCaseInsensitiveMatching() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                text: "Payment complete",
                frame: LoupeRect(x: 24, y: 100, width: 200, height: 30),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("complete", exact: false), in: snapshot)

        #expect(results.map { $0.ref } == ["n1"])
    }

    @Test func findByTextCanUseSemanticText() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "InputBarSendButton",
                role: "button",
                semanticText: "Send",
                frame: LoupeRect(x: 320, y: 700, width: 44, height: 44),
                isVisible: true,
                isEnabled: false,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("Send"), in: snapshot)

        #expect(results.map { $0.ref } == ["n1"])
        #expect(results.first?.text == "Send")
    }

    @Test func findByTextPrefersSpecificTextOverAggregateContainers() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UIView",
                semanticText: "Checkout Pay now",
                frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
            LoupeNode(
                ref: "n2",
                parentRef: "n1",
                kind: .view,
                typeName: "UIButton",
                role: "button",
                semanticText: "Pay now",
                frame: LoupeRect(x: 24, y: 760, width: 342, height: 52),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("Pay now", exact: false), in: snapshot)

        #expect(results.map { $0.ref } == ["n2", "n1"])
    }

    @Test func findByTextSuppressesLargeAggregateContainersWithoutClassNameRules() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "collection",
                parentRef: nil,
                kind: .view,
                typeName: "UserNamedContainer",
                role: "collectionView",
                text: "Search Autocomplete Mixed Data",
                frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
            LoupeNode(
                ref: "wrapper",
                parentRef: nil,
                kind: .view,
                typeName: "UserNamedWrapper",
                text: "Search Autocomplete Mixed Data",
                frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                isVisible: true,
                isEnabled: true,
                isInteractive: true,
                children: ["target"]
            ),
            LoupeNode(
                ref: "target",
                parentRef: "wrapper",
                kind: .view,
                typeName: "UserNamedRow",
                text: "Search Autocomplete",
                frame: LoupeRect(x: 16, y: 120, width: 358, height: 55),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("Search Autocomplete", exact: false), in: snapshot)

        #expect(results.map { $0.ref } == ["target"])
    }

    @Test func findByTextSuppressesSystemChromeSemanticDuplicatesWithoutClassNameRules() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "nav",
                parentRef: nil,
                kind: .view,
                typeName: "UserNamedNavigationWrapper",
                role: "navigationBar",
                frame: LoupeRect(x: 0, y: 0, width: 390, height: 96),
                isVisible: true,
                isEnabled: true,
                isInteractive: false,
                children: ["wrapper", "title"]
            ),
            LoupeNode(
                ref: "wrapper",
                parentRef: "nav",
                kind: .view,
                typeName: "ConflictingUserClassName",
                semanticText: "IGListKit",
                frame: LoupeRect(x: 0, y: 44, width: 390, height: 52),
                isVisible: true,
                isEnabled: true,
                isInteractive: true,
                runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                uiKit: LoupeUIKitProperties(
                    className: "ConflictingUserClassName",
                    tag: 0,
                    alpha: 1,
                    isHidden: false,
                    isOpaque: true,
                    clipsToBounds: false,
                    userInteractionEnabled: true,
                    isFirstResponder: false
                )
            ),
            LoupeNode(
                ref: "title",
                parentRef: "nav",
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                text: "IGListKit",
                frame: LoupeRect(x: 16, y: 108, width: 136, height: 40),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("IGListKit"), in: snapshot)

        #expect(results.map { $0.ref } == ["title"])
    }

    @Test func findByTextPrefersRoleNodesOverInteractiveContainers() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "container",
                parentRef: nil,
                kind: .view,
                typeName: "UITableViewCellContentView",
                text: "Title",
                frame: LoupeRect(x: 0, y: 100, width: 390, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
            LoupeNode(
                ref: "field",
                parentRef: "container",
                kind: .view,
                typeName: "UITextField",
                role: "textField",
                text: "Title",
                frame: LoupeRect(x: 20, y: 110, width: 300, height: 24),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(.text("Title"), in: snapshot)

        #expect(results.map { $0.ref } == ["field", "container"])
    }

    @Test func hiddenNodesAreExcludedByDefault() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "n1",
                parentRef: nil,
                kind: .view,
                typeName: "UIButton",
                role: "button",
                testID: "hidden.button",
                frame: LoupeRect(x: 24, y: 100, width: 200, height: 52),
                isVisible: false,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        #expect(LoupeSnapshotQuery.find(.testID("hidden.button"), in: snapshot).isEmpty)
        #expect(
            LoupeSnapshotQuery.find(
                .testID("hidden.button"),
                in: snapshot,
                options: LoupeQueryOptions(includeHidden: true)
            ).map { $0.ref } == ["n1"]
        )
    }

    private func makeSnapshot(nodes: [LoupeNode]) -> LoupeSnapshot {
        LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: [],
            nodes: Dictionary(uniqueKeysWithValues: nodes.map { ($0.ref, $0) })
        )
    }
}
