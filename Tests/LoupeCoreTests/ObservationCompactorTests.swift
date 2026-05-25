import Foundation
import Testing
@testable import LoupeCore

struct ObservationCompactorTests {
    @Test func compactObservationKeepsVisibleTextAndInteractiveElements() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["n1"],
            nodes: [
                "n1": LoupeNode(
                    ref: "n1",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["n2", "n3", "n4"]
                ),
                "n2": LoupeNode(
                    ref: "n2",
                    parentRef: "n1",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Checkout",
                    frame: LoupeRect(x: 24, y: 80, width: 120, height: 32),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "n3": LoupeNode(
                    ref: "n3",
                    parentRef: "n1",
                    kind: .view,
                    typeName: "UIButton",
                    role: "button",
                    testID: "checkout.payButton",
                    text: "Pay now",
                    frame: LoupeRect(x: 24, y: 760, width: 342, height: 52),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "UIButton",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    )
                ),
                "n4": LoupeNode(
                    ref: "n4",
                    parentRef: "n1",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Offscreen",
                    frame: LoupeRect(x: 24, y: 900, width: 120, height: 32),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.snapshotID == "s1")
        #expect(observation.visibleTexts.map { $0.text } == ["Checkout", "Pay now"])
        #expect(observation.visibleTexts.map { $0.typeName } == ["UILabel", "UIButton"])
        #expect(observation.visibleTexts[1].className == "UIButton")
        #expect(observation.visibleTexts[1].role == "button")
        #expect(observation.visibleTexts[1].testID == "checkout.payButton")
        #expect(observation.interactive.count == 1)
        #expect(observation.interactive[0].ref == "n3")
        #expect(observation.interactive[0].typeName == "UIButton")
        #expect(observation.interactive[0].className == "UIButton")
        #expect(observation.interactive[0].testID == "checkout.payButton")
    }

    @Test func displayTextUsesRenderedAndSemanticText() {
        let renderedNode = LoupeNode(
            ref: "n1",
            parentRef: nil,
            kind: .view,
            typeName: "UILabel",
            renderedText: "Rendered",
            frame: LoupeRect(x: 0, y: 0, width: 100, height: 20),
            isVisible: true,
            isEnabled: true,
            isInteractive: false
        )
        let semanticNode = LoupeNode(
            ref: "n2",
            parentRef: nil,
            kind: .view,
            typeName: "UIButton",
            semanticText: "Send",
            frame: LoupeRect(x: 0, y: 40, width: 100, height: 44),
            isVisible: true,
            isEnabled: true,
            isInteractive: true
        )

        #expect(LoupeObservationCompactor.displayText(for: renderedNode) == "Rendered")
        #expect(LoupeObservationCompactor.displayText(for: semanticNode) == "Send")
    }

    @Test func compactObservationSkipsAggregateContainerVisibleText() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["container"]
                ),
                "container": LoupeNode(
                    ref: "container",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    text: "First Second",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 300),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["first", "second"]
                ),
                "first": LoupeNode(
                    ref: "first",
                    parentRef: "container",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "First",
                    frame: LoupeRect(x: 20, y: 40, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "second": LoupeNode(
                    ref: "second",
                    parentRef: "container",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Second",
                    frame: LoupeRect(x: 20, y: 80, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["first", "second"])
        #expect(observation.visibleTexts.map(\.text) == ["First", "Second"])
    }

    @Test func compactObservationKeepsAggregateTextForSemanticTestIDTargets() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "BookmarkCell",
                    role: "cell",
                    testID: "bookmark.item.created",
                    semanticText: "20260519, Docs",
                    frame: LoupeRect(x: 20, y: 120, width: 360, height: 78),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["title", "category"]
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    testID: "bookmark.item.created.title",
                    text: "20260519",
                    frame: LoupeRect(x: 36, y: 132, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "category": LoupeNode(
                    ref: "category",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    testID: "bookmark.item.created.category",
                    text: "Docs",
                    frame: LoupeRect(x: 36, y: 166, width: 80, height: 20),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["cell", "title", "category"])
        #expect(observation.visibleTexts[0].testID == "bookmark.item.created")
        #expect(observation.visibleTexts[0].text == "20260519, Docs")
    }

    @Test func compactObservationMovesFullscreenAggregateTextAfterSpecificTargets() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["aggregate", "field"]
                ),
                "aggregate": LoupeNode(
                    ref: "aggregate",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UITabBarContainerView",
                    text: "Loupe Search Results Search",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: LoupeUIKitProperties(
                        className: "_UITabBarContainerView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false
                    ),
                    children: ["decorative"]
                ),
                "decorative": LoupeNode(
                    ref: "decorative",
                    parentRef: "aggregate",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "field": LoupeNode(
                    ref: "field",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UISearchBarTextField",
                    role: "textField",
                    testID: "Search Field",
                    text: "Loupe",
                    frame: LoupeRect(x: 16, y: 70, width: 315, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["field", "aggregate"])
    }

    @Test func compactObservationMovesAggregateInteractiveContainersAfterSpecificTargets() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["wrapper"]
                ),
                "messages": LoupeNode(
                    ref: "messages",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "MessagesCollectionView",
                    role: "collectionView",
                    text: "Long message transcript Loupe says hi Send",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "messages",
                    kind: .view,
                    typeName: "TextMessageCell",
                    role: "cell",
                    text: "Long message transcript",
                    frame: LoupeRect(x: 8, y: 120, width: 384, height: 100),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "field": LoupeNode(
                    ref: "field",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "InputTextView",
                    role: "textView",
                    text: "Loupe says hi",
                    frame: LoupeRect(x: 12, y: 720, width: 300, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
                "send": LoupeNode(
                    ref: "send",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "InputBarSendButton",
                    role: "button",
                    text: "Send",
                    frame: LoupeRect(x: 320, y: 720, width: 60, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
                "wrapper": LoupeNode(
                    ref: "wrapper",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILayoutContainerView",
                    text: "Long message transcript Loupe says hi Send",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "UILayoutContainerView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    ),
                    children: ["messages", "field", "send"]
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.interactive.map(\.ref) == ["field", "send", "messages", "wrapper"])
        #expect(observation.interactive.first { $0.ref == "field" }?.text == "Loupe says hi")
        #expect(observation.interactive.first { $0.ref == "send" }?.text == "Send")
        #expect(observation.interactive.first { $0.ref == "messages" }?.text == nil)
        #expect(observation.interactive.first { $0.ref == "wrapper" }?.text == nil)
    }

    @Test func compactObservationSuppressesAppleSystemAggregateInteractiveContainers() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["container"]
                ),
                "container": LoupeNode(
                    ref: "container",
                    parentRef: "root",
                    kind: .view,
                    typeName: "ProjectNamedContainer",
                    semanticText: "Feed View",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["title"]
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "container",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Feed View",
                    frame: LoupeRect(x: 16, y: 100, width: 140, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["title"])
        #expect(!observation.interactive.contains { $0.ref == "container" })
    }

    @Test func compactObservationSuppressesRootWindowsFromInteractiveContext() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["window"],
            nodes: [
                "window": LoupeNode(
                    ref: "window",
                    parentRef: nil,
                    kind: .window,
                    typeName: "ConflictingUserWindowName",
                    role: "window",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["button"]
                ),
                "button": LoupeNode(
                    ref: "button",
                    parentRef: "window",
                    kind: .view,
                    typeName: "UIButton",
                    role: "button",
                    text: "Pay",
                    frame: LoupeRect(x: 20, y: 80, width: 100, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.interactive.map(\.ref) == ["button"])
    }

    @Test func compactObservationOmitsScrollableContainerInteractiveText() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["table"]
                ),
                "table": LoupeNode(
                    ref: "table",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableView",
                    role: "tableView",
                    text: "Deleted Item Visible Item",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "table",
                    kind: .view,
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Visible Item",
                    frame: LoupeRect(x: 0, y: 120, width: 400, height: 64),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["cell"])
        #expect(observation.interactive.first { $0.ref == "cell" }?.text == "Visible Item")
        #expect(observation.interactive.first { $0.ref == "table" }?.text == nil)
    }

    @Test func compactObservationSuppressesSystemChromeSemanticDuplicateText() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["nav", "title"]
                ),
                "nav": LoupeNode(
                    ref: "nav",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UserNamedNavigationWrapper",
                    role: "navigationBar",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 96),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["wrapper"]
                ),
                "wrapper": LoupeNode(
                    ref: "wrapper",
                    parentRef: "nav",
                    kind: .view,
                    typeName: "ConflictingUserClassName",
                    semanticText: "IGListKit",
                    frame: LoupeRect(x: 0, y: 44, width: 400, height: 52),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    uiKit: LoupeUIKitProperties(
                        viewControllerRole: "navigationController",
                        className: "ConflictingUserClassName",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: true,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    ),
                    children: ["hidden-title"]
                ),
                "hidden-title": LoupeNode(
                    ref: "hidden-title",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "IGListKit",
                    frame: LoupeRect(x: 166, y: 60, width: 68, height: 24),
                    isVisible: false,
                    isEnabled: true,
                    isInteractive: false
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "IGListKit",
                    frame: LoupeRect(x: 16, y: 108, width: 136, height: 40),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["title"])
        #expect(!observation.interactive.contains { $0.ref == "wrapper" })
    }

    @Test func compactObservationKeepsCustomSemanticChromeText() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["nav"]
                ),
                "nav": LoupeNode(
                    ref: "nav",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UINavigationBar",
                    role: "navigationBar",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 96),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["custom-title"]
                ),
                "custom-title": LoupeNode(
                    ref: "custom-title",
                    parentRef: "nav",
                    kind: .view,
                    typeName: "HostedTitleView",
                    semanticText: "Only Custom Title",
                    frame: LoupeRect(x: 100, y: 44, width: 200, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App")
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["custom-title"])
        #expect(observation.interactive.map(\.ref) == ["custom-title"])
    }

    @Test func compactObservationSuppressesDismissedAppleModalAggregateTextAndBackdrop() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["transition"]
                ),
                "transition": LoupeNode(
                    ref: "transition",
                    parentRef: "root",
                    kind: .view,
                    typeName: "ProjectNamedTransition",
                    semanticText: "Delete Report",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["backdrop", "hidden-alert"]
                ),
                "backdrop": LoupeNode(
                    ref: "backdrop",
                    parentRef: "transition",
                    kind: .view,
                    typeName: "ProjectNamedBackdrop",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore")
                ),
                "hidden-alert": LoupeNode(
                    ref: "hidden-alert",
                    parentRef: "transition",
                    kind: .view,
                    typeName: "ProjectNamedAlert",
                    semanticText: "Delete Report",
                    frame: LoupeRect(x: 360, y: 190, width: 2, height: 1),
                    isVisible: false,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore")
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(!observation.visibleTexts.contains { $0.ref == "transition" })
        #expect(!observation.interactive.contains { $0.ref == "backdrop" })
    }

    @Test func compactObservationKeepsCustomRuntimeModalNamedOverlay() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["overlay"]
                ),
                "overlay": LoupeNode(
                    ref: "overlay",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIPopoverDimmingView",
                    semanticText: "Delete Report",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App")
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.contains { $0.ref == "overlay" })
        #expect(observation.interactive.contains { $0.ref == "overlay" })
    }

    @Test func compactObservationSuppressesSystemOwnedCellAccessoryButtons() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Basic Example",
                    frame: LoupeRect(x: 0, y: 120, width: 400, height: 53),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["accessory"]
                ),
                "accessory": LoupeNode(
                    ref: "accessory",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "ConflictingUserClassName",
                    role: "button",
                    frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    accessibility: LoupeAccessibility(
                        frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                        isElement: false
                    ),
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    uiKit: LoupeUIKitProperties(
                        className: "ConflictingUserClassName",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false,
                        control: LoupeUIControlProperties(controlEvents: ["touchUpInside"]),
                        button: LoupeUIButtonProperties()
                    ),
                    children: ["chevron"]
                ),
                "chevron": LoupeNode(
                    ref: "chevron",
                    parentRef: "accessory",
                    kind: .view,
                    typeName: "UIImageView",
                    role: "image",
                    frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    uiKit: LoupeUIKitProperties(
                        className: "UIImageView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: true,
                        userInteractionEnabled: false,
                        isFirstResponder: false,
                        imageView: LoupeUIImageViewProperties()
                    )
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["cell"])
        #expect(observation.interactive.map(\.ref) == ["cell"])
    }

    @Test func compactObservationKeepsCustomCellAccessoryButtonsEvenWithSystemClassNames() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Custom Example",
                    frame: LoupeRect(x: 0, y: 120, width: 400, height: 53),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App"),
                    children: ["accessory"]
                ),
                "accessory": LoupeNode(
                    ref: "accessory",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "_UITableCellAccessoryButton",
                    role: "button",
                    frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    accessibility: LoupeAccessibility(
                        frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                        isElement: false
                    ),
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App"),
                    uiKit: LoupeUIKitProperties(
                        className: "_UITableCellAccessoryButton",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false,
                        control: LoupeUIControlProperties(controlEvents: ["touchUpInside"]),
                        button: LoupeUIButtonProperties()
                    ),
                    children: ["chevron"]
                ),
                "chevron": LoupeNode(
                    ref: "chevron",
                    parentRef: "accessory",
                    kind: .view,
                    typeName: "UIImageView",
                    role: "image",
                    frame: LoupeRect(x: 370, y: 139, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App"),
                    uiKit: LoupeUIKitProperties(
                        className: "UIImageView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: true,
                        userInteractionEnabled: false,
                        isFirstResponder: false,
                        imageView: LoupeUIImageViewProperties()
                    )
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visibleTexts.map(\.ref) == ["cell"])
        #expect(observation.interactive.map(\.ref).contains("accessory"))
    }

    @Test func compactObservationMarksLargeCustomLeafViewsAsVisualSurfaces() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["chart", "label"]
                ),
                "chart": LoupeNode(
                    ref: "chart",
                    parentRef: "root",
                    kind: .view,
                    typeName: "BarChartView",
                    frame: LoupeRect(x: 0, y: 120, width: 400, height: 420),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.Charts"),
                    uiKit: LoupeUIKitProperties(
                        className: "BarChartView",
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
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Bar Chart",
                    frame: LoupeRect(x: 20, y: 60, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore")
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visualSurfaces.count == 1)
        #expect(observation.visualSurfaces[0].ref == "chart")
        #expect(observation.visualSurfaces[0].frameworkBundleIdentifier == "com.example.Charts")
    }

    @Test func compactObservationMarksWebKitContentViewsAsVisualSurfaces() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["webContent"]
                ),
                "webContent": LoupeNode(
                    ref: "webContent",
                    parentRef: "root",
                    kind: .view,
                    typeName: "WKContentView",
                    frame: LoupeRect(x: 0, y: 100, width: 400, height: 1200),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.WebKit"),
                    uiKit: LoupeUIKitProperties(
                        className: "WKContentView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    ),
                    children: ["image"]
                ),
                "image": LoupeNode(
                    ref: "image",
                    parentRef: "webContent",
                    kind: .view,
                    typeName: "UIImageView",
                    frame: LoupeRect(x: 0, y: 120, width: 400, height: 220),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visualSurfaces.count == 1)
        #expect(observation.visualSurfaces[0].ref == "webContent")
        #expect(observation.visualSurfaces[0].note.contains("WebKit content surface"))
    }

    @Test func compactObservationMarksTextlessSwiftUIHostingViewsAsVisualSurfaces() {
        let snapshot = LoupeSnapshot(
            id: "s1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["hosting"]
                ),
                "hosting": LoupeNode(
                    ref: "hosting",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIHostingView<RegistrationPermissionsView>",
                    frame: LoupeRect(x: 16, y: 100, width: 368, height: 620),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.SwiftUI"),
                    uiKit: LoupeUIKitProperties(
                        className: "_UIHostingView<RegistrationPermissionsView>",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: true,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    ),
                    children: ["internal"]
                ),
                "internal": LoupeNode(
                    ref: "internal",
                    parentRef: "hosting",
                    kind: .view,
                    typeName: "_UIInheritedView",
                    frame: LoupeRect(x: 28, y: 700, width: 344, height: 50),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let observation = LoupeObservationCompactor.compact(snapshot)

        #expect(observation.visualSurfaces.count == 1)
        #expect(observation.visualSurfaces[0].ref == "hosting")
        #expect(observation.visualSurfaces[0].frameworkBundleIdentifier == "com.apple.SwiftUI")
        #expect(observation.visualSurfaces[0].note.contains("SwiftUI hosting surface"))
    }
}
