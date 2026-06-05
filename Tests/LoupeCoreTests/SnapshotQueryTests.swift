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

    @Test func findByTestIDPrefersPlatformBackedProbeOverSyntheticProbe() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "synthetic",
                parentRef: nil,
                kind: .view,
                typeName: "LoupeRegisteredProbe",
                role: "button",
                testID: "openimmersive.enterStreamURL",
                text: "Enter Stream URL",
                frame: LoupeRect(x: 725.5, y: 526, width: 207.5, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true,
                custom: [
                    "synthetic": .bool(true),
                    "observationBackend": .string("registered-probes"),
                ]
            ),
            LoupeNode(
                ref: "backing",
                parentRef: nil,
                kind: .view,
                typeName: "LoupeFallbackFrameView",
                role: "button",
                testID: "openimmersive.enterStreamURL",
                text: "Enter Stream URL",
                frame: LoupeRect(x: 485.5, y: 591, width: 207.5, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
        ])

        let results = LoupeSnapshotQuery.find(
            .testID("openimmersive.enterStreamURL"),
            in: snapshot,
            options: LoupeQueryOptions(includeHidden: true)
        )

        #expect(results.map { $0.ref } == ["backing", "synthetic"])
    }

    @Test func platformBackedPreferenceDropsOnlySyntheticDuplicateWithSameSemantics() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "synthetic",
                parentRef: nil,
                kind: .view,
                typeName: "LoupeRegisteredProbe",
                role: "button",
                testID: "openimmersive.enterStreamURL",
                text: "Enter Stream URL",
                frame: LoupeRect(x: 725.5, y: 526, width: 207.5, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true,
                custom: [
                    "synthetic": .bool(true),
                    "observationBackend": .string("registered-probes"),
                ]
            ),
            LoupeNode(
                ref: "backing",
                parentRef: nil,
                kind: .view,
                typeName: "LoupeFallbackFrameView",
                role: "button",
                testID: "openimmersive.enterStreamURL",
                text: "Enter Stream URL",
                frame: LoupeRect(x: 485.5, y: 591, width: 207.5, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true
            ),
            LoupeNode(
                ref: "differentProbe",
                parentRef: nil,
                kind: .view,
                typeName: "LoupeRegisteredProbe",
                role: "button",
                testID: "openimmersive.openBookmarks",
                text: "Bookmarks",
                frame: LoupeRect(x: 500, y: 650, width: 160, height: 44),
                isVisible: true,
                isEnabled: true,
                isInteractive: true,
                custom: [
                    "synthetic": .bool(true),
                    "observationBackend": .string("registered-probes"),
                ]
            ),
        ])
        let matches = [
            LoupeQueryResult(node: snapshot.nodes["synthetic"]!),
            LoupeQueryResult(node: snapshot.nodes["backing"]!),
            LoupeQueryResult(node: snapshot.nodes["differentProbe"]!),
        ]

        let filtered = LoupeSnapshotQuery.preferPlatformBackedMatches(matches, in: snapshot)

        #expect(filtered.map(\.ref) == ["backing", "differentProbe"])
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

    @Test func includeHiddenResultsPreferVisibleMatches() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "offscreen",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                text: "Repeated title",
                frame: LoupeRect(x: 24, y: -120, width: 200, height: 40),
                isVisible: false,
                isEnabled: true,
                isInteractive: false
            ),
            LoupeNode(
                ref: "visible",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                text: "Repeated title",
                frame: LoupeRect(x: 24, y: 240, width: 200, height: 40),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
        ])

        let results = LoupeSnapshotQuery.find(
            .text("Repeated title", exact: true),
            in: snapshot,
            options: LoupeQueryOptions(includeHidden: true)
        )

        #expect(results.map { $0.ref } == ["visible", "offscreen"])
    }

    @Test func occlusionVisibilityIncludesOffscreenVisibleNodesButNotHiddenNodes() {
        let snapshot = makeSnapshot(nodes: [
            LoupeNode(
                ref: "hidden",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                testID: "fixture.card",
                text: "Fixture",
                frame: LoupeRect(x: 24, y: 160, width: 200, height: 40),
                isVisible: false,
                isEnabled: true,
                isInteractive: false
            ),
            LoupeNode(
                ref: "offscreen",
                parentRef: nil,
                kind: .view,
                typeName: "UILabel",
                role: "staticText",
                testID: "fixture.card",
                text: "Fixture",
                frame: LoupeRect(x: 24, y: 900, width: 200, height: 40),
                isVisible: true,
                isEnabled: true,
                isInteractive: false
            ),
        ])

        #expect(
            LoupeSnapshotQuery.find(
                .testID("fixture.card"),
                in: snapshot,
                options: LoupeQueryOptions(visibilityMode: .surface)
            ).isEmpty
        )
        #expect(
            LoupeSnapshotQuery.find(
                .testID("fixture.card"),
                in: snapshot,
                options: LoupeQueryOptions(visibilityMode: .occlusion)
            ).map { $0.ref } == ["offscreen"]
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
