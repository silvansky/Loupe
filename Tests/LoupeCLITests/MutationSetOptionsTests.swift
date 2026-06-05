@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct MutationSetOptionsTests {
    @Test func setMutationsAnimateByDefault() throws {
        let options = try MutationSetOptions([
            "--test-id", "example.card",
            "frame",
            "20,120,220,80",
        ])

        #expect(options.request.animation?.duration == 0.25)
        #expect(options.request.animation?.delay == 0)
        #expect(options.request.animation?.curve == "easeInOut")
    }

    @Test func noAnimateDisablesSetMutationAnimation() throws {
        let options = try MutationSetOptions([
            "--test-id", "example.card",
            "text",
            "Updated",
            "--no-animate",
            "--duration", "0.4",
        ])

        #expect(options.request.animation == nil)
    }

    @Test func setMutationAnimationOptionsOverrideDefaults() throws {
        let options = try MutationSetOptions([
            "--test-id", "example.card",
            "alpha",
            "0.5",
            "--duration", "0.4",
            "--delay", "0.1",
            "--curve", "linear",
        ])

        #expect(options.request.animation?.duration == 0.4)
        #expect(options.request.animation?.delay == 0.1)
        #expect(options.request.animation?.curve == "linear")
    }

    @Test func numericTextValuesInferAsStrings() throws {
        let options = try MutationSetOptions([
            "--ref", "n20",
            "text",
            "20260519",
        ])

        #expect(options.request.value == .string("20260519"))
    }

    @Test func trySelfSizingOptInIsParsed() throws {
        let options = try MutationSetOptions([
            "--test-id", "cell.title",
            "layout.hugging.vertical",
            "251",
            "--try-self-sizing",
        ])

        #expect(options.request.trySelfSizing)
    }

    @Test func includeHiddenOptInIsParsed() throws {
        let options = try MutationSetOptions([
            "--text", "Repeated title",
            "textColor",
            "--color", "#ff3366",
            "--include-hidden",
        ])

        #expect(options.request.includeHidden)
    }

    @Test func fontSizeInfersAsScalarNumber() throws {
        let options = try MutationSetOptions([
            "--ref", "n20",
            "fontSize",
            "26",
        ])

        #expect(options.request.value == .int(26))
    }

    @Test func styleFontSizeAliasInfersAsScalarNumber() throws {
        let options = try MutationSetOptions([
            "--ref", "n20",
            "style.fontSize",
            "26.5",
        ])

        #expect(options.request.value == .double(26.5))
    }

    @Test func setMutationCanCarrySnapshotForRefResolution() throws {
        let options = try MutationSetOptions([
            "--snapshot", "/tmp/loupe-report/snapshot.json",
            "--ref", "n96",
            "textColor",
            "--color", "#ff3366",
        ])

        #expect(options.snapshotURL?.path == "/tmp/loupe-report/snapshot.json")
        #expect(options.request.selector.kind == .ref)
        #expect(options.request.selector.value == "n96")
    }

    @Test func setMutationResolvesSnapshotRefDriftAgainstLiveSnapshot() throws {
        let request = LoupeMutationRequest(
            selector: LoupeMutationSelector(kind: .ref, value: "n96"),
            property: "textColor",
            value: .color(LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1)),
            animation: nil
        )
        let referenceSnapshot = snapshot(nodes: [
            "root": root(children: ["n96"]),
            "n96": searchField(ref: "n96"),
        ])
        let liveSnapshot = snapshot(nodes: [
            "root": root(children: ["n57", "n96"]),
            "n57": searchField(ref: "n57"),
            "n96": tabBar(ref: "n96"),
        ])

        let resolved = try LoupeCLI.requestByResolvingMutationSnapshotRef(
            request,
            referenceSnapshot: referenceSnapshot,
            liveSnapshot: liveSnapshot
        )

        #expect(resolved.selector.kind == .ref)
        #expect(resolved.selector.value == "n57")
    }

    private func snapshot(nodes: [String: LoupeNode]) -> LoupeSnapshot {
        LoupeSnapshot(
            id: UUID().uuidString,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 402, height: 874), scale: 3),
            rootRefs: ["root"],
            nodes: nodes
        )
    }

    private func root(children: [String]) -> LoupeNode {
        LoupeNode(
            ref: "root",
            parentRef: nil,
            kind: .view,
            typeName: "UIView",
            frame: LoupeRect(x: 0, y: 0, width: 402, height: 874),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            children: children
        )
    }

    private func searchField(ref: String) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "UISearchBarTextField",
            role: "textField",
            text: "Dune",
            frame: LoupeRect(x: 16, y: 70, width: 315, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UISearchBarTextField",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: true
            )
        )
    }

    private func tabBar(ref: String) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "UITabBar",
            role: "tabBar",
            frame: LoupeRect(x: 0, y: 790, width: 402, height: 84),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UITabBar",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: false
            )
        )
    }
}
