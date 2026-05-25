@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct SnapshotDiffTests {
    @Test func reportsStyleColorChanges() {
        let before = snapshot(
            id: "before",
            node: node(style: LoupeStyle())
        )
        let after = snapshot(
            id: "after",
            node: node(style: LoupeStyle(
                backgroundColor: LoupeColor(red: 1, green: 0.894, blue: 0.902, alpha: 1),
                tintColor: LoupeColor(red: 0, green: 0.478, blue: 1, alpha: 1),
                shadowOpacity: 0.2
            ))
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.backgroundColor"
                && change.before == nil
                && change.after == "rgba(1,0.894,0.902,1)"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.tintColor"
                && change.after == "rgba(0,0.478,1,1)"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "style.shadowOpacity"
                && change.after == "0.2"
        })
    }

    @Test func changedNodeSummaryUsesTextPreview() {
        let before = snapshot(
            id: "before",
            node: textNode(text: String(repeating: "A", count: 200))
        )
        let after = snapshot(
            id: "after",
            node: textNode(text: String(repeating: "B", count: 200))
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].summary.contains("\(String(repeating: "B", count: 140))..."))
        #expect(!diff.changed[0].summary.contains(String(repeating: "B", count: 141)))
    }

    @Test func reportsScrollViewPropertyChanges() {
        let before = snapshot(
            id: "before",
            node: scrollNode(offsetY: 0, paging: false)
        )
        let after = snapshot(
            id: "after",
            node: scrollNode(offsetY: 240, paging: true)
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.contentOffset"
                && change.before == "0,0"
                && change.after == "0,240"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.isPagingEnabled"
                && change.before == "false"
                && change.after == "true"
        })
        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.bounces"
                && change.before == "true"
                && change.after == "false"
        })
    }

    @Test func keepsScrollContainersStableWhenAggregateTextChanges() {
        let before = snapshot(
            id: "before",
            node: scrollNode(offsetY: 0, paging: false, testID: nil, semanticText: "First visible row")
        )
        let after = snapshot(
            id: "after",
            node: scrollNode(offsetY: 500, paging: false, testID: nil, semanticText: "Later visible row")
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.appeared.isEmpty)
        #expect(diff.disappeared.isEmpty)
        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].changes.contains { change in
            change.field == "uiKit.scrollView.contentOffset"
                && change.before == "0,0"
                && change.after == "0,500"
        })
        #expect(!diff.changed[0].changes.contains { $0.field == "text" })
        #expect(!diff.changed[0].summary.contains("Later visible row"))
    }

    @Test func suppressesAggregateWrapperTextInDiffSummaries() {
        let before = aggregateWrapperSnapshot(id: "before", wrapperText: "First aggregate text", childText: "First")
        let after = aggregateWrapperSnapshot(id: "after", wrapperText: "Second aggregate text", childText: "Second")

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(!diff.appeared.contains { $0.typeName == "UIDropShadowView" })
        #expect(!diff.disappeared.contains { $0.typeName == "UIDropShadowView" })
        #expect(!diff.changed.contains { $0.key.contains("UIDropShadowView") })
        #expect(diff.appeared.contains { $0.typeName == "UILabel" && $0.text == "Second" })
        #expect(diff.disappeared.contains { $0.typeName == "UILabel" && $0.text == "First" })
    }

    @Test func suppressesSystemChromeSemanticDuplicatesInDiffSummaries() {
        let before = systemChromeSnapshot(id: "before", title: "Before")
        let after = systemChromeSnapshot(id: "after", title: "After")

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(!diff.appeared.contains { $0.typeName == "ConflictingUserClassName" })
        #expect(!diff.disappeared.contains { $0.typeName == "ConflictingUserClassName" })
        #expect(!diff.changed.contains { $0.key.contains("ConflictingUserClassName") })
        #expect(diff.appeared.contains { $0.typeName == "UILabel" && $0.text == "After" })
        #expect(diff.disappeared.contains { $0.typeName == "UILabel" && $0.text == "Before" })
    }

    @Test func suppressesSystemOwnedPassiveDecorationChangesInDiffSummaries() {
        let before = snapshot(
            id: "before",
            node: passiveDecorationNode(visible: false, framework: "com.apple.UIKitCore")
        )
        let after = snapshot(
            id: "after",
            node: passiveDecorationNode(visible: true, framework: "com.apple.UIKitCore")
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.appeared.isEmpty)
        #expect(diff.disappeared.isEmpty)
        #expect(diff.changed.isEmpty)
    }

    @Test func keepsCustomPassiveDecorationChangesInDiffSummaries() {
        let before = snapshot(
            id: "before",
            node: passiveDecorationNode(visible: false, framework: "com.example.App")
        )
        let after = snapshot(
            id: "after",
            node: passiveDecorationNode(visible: true, framework: "com.example.App")
        )

        let diff = LoupeCLI.snapshotDiff(before: before, after: after)

        #expect(diff.changed.count == 1)
        #expect(diff.changed[0].changes.contains { $0.field == "isVisible" })
    }

    private func snapshot(id: String, node: LoupeNode) -> LoupeSnapshot {
        LoupeSnapshot(
            id: id,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: [node.ref],
            nodes: [node.ref: node]
        )
    }

    private func node(style: LoupeStyle?) -> LoupeNode {
        LoupeNode(
            ref: "n1",
            parentRef: nil,
            kind: .view,
            typeName: "UIView",
            testID: "settings.cell.background",
            frame: LoupeRect(x: 0, y: 100, width: 390, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: style
        )
    }

    private func textNode(text: String) -> LoupeNode {
        LoupeNode(
            ref: "message",
            parentRef: nil,
            kind: .view,
            typeName: "UILabel",
            role: "staticText",
            testID: "message.preview",
            text: text,
            frame: LoupeRect(x: 0, y: 100, width: 390, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: false
        )
    }

    private func scrollNode(
        offsetY: Double,
        paging: Bool,
        testID: String? = "results.scroll",
        semanticText: String? = nil
    ) -> LoupeNode {
        LoupeNode(
            ref: "scroll",
            parentRef: nil,
            kind: .view,
            typeName: "UIScrollView",
            role: "scrollView",
            testID: testID,
            semanticText: semanticText,
            frame: LoupeRect(x: 0, y: 0, width: 390, height: 500),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UIScrollView",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: true,
                userInteractionEnabled: true,
                isFirstResponder: false,
                scrollView: LoupeUIScrollViewProperties(
                    contentOffset: LoupePoint(x: 0, y: offsetY),
                    contentSize: LoupeSize(width: 390, height: 1_200),
                    adjustedContentInset: LoupeInsets(top: 0, left: 0, bottom: 34, right: 0),
                    isScrollEnabled: true,
                    isPagingEnabled: paging,
                    bounces: !paging,
                    alwaysBounceVertical: true,
                    alwaysBounceHorizontal: false
                )
            )
        )
    }

    private func passiveDecorationNode(visible: Bool, framework: String) -> LoupeNode {
        LoupeNode(
            ref: "decoration",
            parentRef: nil,
            kind: .view,
            typeName: "ConflictingUserClassName",
            frame: LoupeRect(x: 0, y: 0, width: 390, height: 96),
            isVisible: visible,
            isEnabled: true,
            isInteractive: false,
            runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: framework),
            uiKit: LoupeUIKitProperties(
                className: "ConflictingUserClassName",
                tag: 0,
                alpha: 1,
                isHidden: !visible,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: false,
                isFirstResponder: false
            )
        )
    }

    private func aggregateWrapperSnapshot(id: String, wrapperText: String, childText: String) -> LoupeSnapshot {
        LoupeSnapshot(
            id: id,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["wrapper"],
            nodes: [
                "wrapper": LoupeNode(
                    ref: "wrapper",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIDropShadowView",
                    text: wrapperText,
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["label"]
                ),
                "label": LoupeNode(
                    ref: "label",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: childText,
                    frame: LoupeRect(x: 24, y: 120, width: 200, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )
    }

    private func systemChromeSnapshot(id: String, title: String) -> LoupeSnapshot {
        LoupeSnapshot(
            id: id,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["nav"],
            nodes: [
                "nav": LoupeNode(
                    ref: "nav",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UserNamedNavigationWrapper",
                    role: "navigationBar",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 96),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["wrapper", "label"]
                ),
                "wrapper": LoupeNode(
                    ref: "wrapper",
                    parentRef: "nav",
                    kind: .view,
                    typeName: "ConflictingUserClassName",
                    semanticText: title,
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
                "label": LoupeNode(
                    ref: "label",
                    parentRef: "nav",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: title,
                    frame: LoupeRect(x: 16, y: 108, width: 136, height: 40),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )
    }
}
