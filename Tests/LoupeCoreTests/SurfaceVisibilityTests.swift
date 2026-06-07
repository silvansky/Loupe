import Foundation
import Testing
@testable import LoupeCore

struct SurfaceVisibilityTests {
    @Test func occludedPresentedContentIsExcludedFromDefaultDiscoverySurfaces() {
        let snapshot = Self.presentedScreenSnapshot()

        let compact = LoupeObservationCompactor.compact(snapshot)
        #expect(compact.visibleTexts.map(\.text).contains("Login"))
        #expect(compact.visibleTexts.map(\.text).contains("Enter Username"))
        #expect(!compact.visibleTexts.map(\.text).contains("Your Profit..!"))
        #expect(!compact.visibleTexts.map(\.text).contains("Get Started"))

        let visibleButtons = LoupeSnapshotQuery.find(.role("button"), in: snapshot)
        #expect(visibleButtons.map(\.ref) == ["loginButton"])

        let allButtons = LoupeSnapshotQuery.find(
            .role("button"),
            in: snapshot,
            options: LoupeQueryOptions(includeHidden: true)
        )
        #expect(allButtons.map(\.ref) == ["loginButton", "oldButton"])

        let screenMap = LoupeScreenMapper.map(snapshot)
        #expect(screenMap.elements.map(\.ref).contains("loginButton"))
        #expect(!screenMap.elements.map(\.ref).contains("oldButton"))

        let accessibilityTree = LoupeAccessibilityTree.build(from: snapshot)
        #expect(accessibilityTree.nodes.values.map(\.sourceRef).contains("loginButton"))
        #expect(!accessibilityTree.nodes.values.map(\.sourceRef).contains("oldButton"))
    }

    @Test func unknownScreenSizeKeepsRawVisibleNodesDiscoverable() {
        let snapshot = LoupeSnapshot(
            id: "zero-screen",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 0, height: 0), scale: 1),
            rootRefs: ["root"],
            nodes: [
                "root": Self.node(
                    ref: "root",
                    kind: .application,
                    typeName: "WKApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 0, height: 0),
                    children: ["summary"]
                ),
                "summary": Self.node(
                    ref: "summary",
                    parentRef: "root",
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    text: "Tempo session summary",
                    frame: LoupeRect(x: 12, y: 65, width: 131, height: 102)
                ),
            ]
        )

        let queryResults = LoupeSnapshotQuery.find(.text("Tempo session summary"), in: snapshot)
        #expect(queryResults.map(\.ref) == ["summary"])

        let compact = LoupeObservationCompactor.compact(snapshot)
        #expect(compact.visibleTexts.map(\.ref).contains("summary"))

        let screenMap = LoupeScreenMapper.map(snapshot)
        #expect(screenMap.elements.map(\.ref).contains("summary"))
    }

    @Test func semanticTestIDContainersAreDiscoverableWhenPresentedOnScreen() {
        let snapshot = Self.alertSnapshot()

        let defaultResults = LoupeSnapshotQuery.find(.testID("example.components.alert"), in: snapshot)
        #expect(defaultResults.map(\.ref) == ["alert"])

        let waitLikeResult = LoupeSnapshotQuery.first(
            .testID("example.components.alert"),
            in: snapshot,
            options: LoupeQueryOptions(includeHidden: false, includeDisabled: true, maxResults: 1)
        )
        #expect(waitLikeResult?.ref == "alert")
        #expect(waitLikeResult?.isVisible == true)
    }

    @Test func exactIdentityContainersWithVisibleDescendantsAreDiscoverable() {
        let snapshot = LoupeSnapshot(
            id: "scroll-container-identity",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": Self.node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    children: ["table"]
                ),
                "table": Self.node(
                    ref: "table",
                    parentRef: "app",
                    testID: "example.customerList",
                    typeName: "UITableView",
                    role: "tableView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isInteractive: true,
                    uiKit: Self.uiKitScrollView(),
                    children: ["row"]
                ),
                "row": Self.node(
                    ref: "row",
                    parentRef: "table",
                    testID: "example.customer.1",
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Customer 1",
                    frame: LoupeRect(x: 16, y: 120, width: 180, height: 44),
                    backgroundAlpha: 1,
                    isInteractive: true
                ),
            ]
        )

        let testIDResults = LoupeSnapshotQuery.find(.testID("example.customerList"), in: snapshot)
        #expect(testIDResults.map(\.ref) == ["table"])
        #expect(testIDResults.first?.isVisible == true)

        let refResults = LoupeSnapshotQuery.find(.ref("table"), in: snapshot)
        #expect(refResults.map(\.ref) == ["table"])
    }

    @Test func aggregateSemanticContainersDoNotOccludeAccessibleProbeContent() {
        let probeFrame = LoupeRect(x: 0, y: 153, width: 390, height: 608)
        let snapshot = LoupeSnapshot(
            id: "aggregate-semantic-container",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": Self.node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    children: ["content", "tabContainer"]
                ),
                "content": Self.node(
                    ref: "content",
                    parentRef: "app",
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    children: ["probe"]
                ),
                "probe": Self.node(
                    ref: "probe",
                    parentRef: "content",
                    testID: "example.fixtures.swiftui.probe",
                    typeName: "UIView",
                    semanticText: "iOS SwiftUI probe",
                    frame: probeFrame,
                    accessibility: LoupeAccessibility(
                        identifier: "example.fixtures.swiftui.probe",
                        label: "iOS SwiftUI probe",
                        frame: probeFrame,
                        isElement: true
                    )
                ),
                "tabContainer": Self.node(
                    ref: "tabContainer",
                    parentRef: "app",
                    typeName: "UIView",
                    semanticText: "SwiftUI Web Keyboard Nested SwiftUI Web Keyboard Nested",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    children: ["tabBar"]
                ),
                "tabBar": Self.node(
                    ref: "tabBar",
                    parentRef: "tabContainer",
                    typeName: "UITabBar",
                    role: "tabBar",
                    semanticText: "SwiftUI Web Keyboard Nested",
                    frame: LoupeRect(x: 0, y: 761, width: 390, height: 83),
                    backgroundAlpha: 1
                ),
            ]
        )

        #expect(LoupeSurfaceVisibility.visibleNodeRefs(in: snapshot, includesOffscreen: true).contains("probe"))

        let accessibilityTree = LoupeAccessibilityTree.build(from: snapshot)
        let probeNode = accessibilityTree.nodes.values.first {
            $0.testID == "example.fixtures.swiftui.probe"
        }
        #expect(probeNode?.label == "iOS SwiftUI probe")
        #expect(probeNode?.sourceRef == "probe")
    }

    @Test func overlappingSyntheticProbesDoNotOccludeChildProbeTargets() {
        let snapshot = LoupeSnapshot(
            id: "watch-probe-overlap",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 208, height: 248), scale: 2),
            rootRefs: ["app"],
            nodes: [
                "app": Self.node(
                    ref: "app",
                    kind: .application,
                    typeName: "WKApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 208, height: 248),
                    children: ["root", "settings"]
                ),
                "root": Self.node(
                    ref: "root",
                    parentRef: "app",
                    testID: "brush.root",
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    text: "Brush root",
                    frame: LoupeRect(x: 2, y: 44.5, width: 204, height: 167.5),
                    custom: ["loupe.probe": .bool(true)],
                    children: ["minus", "plus"]
                ),
                "settings": Self.node(
                    ref: "settings",
                    parentRef: "app",
                    testID: "brush.settings",
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    text: "Brush settings",
                    frame: LoupeRect(x: 2, y: 44.5, width: 204, height: 167.5),
                    custom: ["loupe.probe": .bool(true)]
                ),
                "minus": Self.node(
                    ref: "minus",
                    parentRef: "root",
                    testID: "brush.settings.minus",
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    text: "Decrease duration",
                    frame: LoupeRect(x: 2, y: 172, width: 99.5, height: 40),
                    custom: ["loupe.probe": .bool(true)]
                ),
                "plus": Self.node(
                    ref: "plus",
                    parentRef: "root",
                    testID: "brush.settings.plus",
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    text: "Increase duration",
                    frame: LoupeRect(x: 106.5, y: 172, width: 99.5, height: 40),
                    custom: ["loupe.probe": .bool(true)]
                ),
            ]
        )

        #expect(LoupeSnapshotQuery.find(.testID("brush.settings.plus"), in: snapshot).map(\.ref) == ["plus"])
        #expect(LoupeSnapshotQuery.find(.ref("plus"), in: snapshot).map(\.ref) == ["plus"])

        let accessibilityTree = LoupeAccessibilityTree.build(from: snapshot)
        #expect(LoupeAccessibilityTreeQuery.find(.testID("brush.settings.plus"), in: accessibilityTree).map(\.sourceRef) == ["plus"])
    }

    @Test func interactiveAccessibilityElementTargetsWithoutDisplayTextAreDiscoverable() {
        let snapshot = LoupeSnapshot(
            id: "accessibility-element-surface-visibility",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 440, height: 956), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": Self.node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    children: ["content", "add"]
                ),
                "content": Self.node(
                    ref: "content",
                    parentRef: "app",
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    backgroundAlpha: 1
                ),
                "add": Self.node(
                    ref: "add",
                    parentRef: "app",
                    testID: "bookmark.add",
                    typeName: "UIBarButtonItem",
                    role: "button",
                    frame: LoupeRect(x: 380, y: 66, width: 36, height: 36),
                    isInteractive: true,
                    accessibility: LoupeAccessibility(
                        identifier: "bookmark.add",
                        traits: ["button"],
                        frame: LoupeRect(x: 380, y: 66, width: 36, height: 36),
                        activationPoint: LoupePoint(x: 398, y: 84),
                        isElement: true
                    )
                ),
            ]
        )

        let results = LoupeSnapshotQuery.find(.testID("bookmark.add"), in: snapshot)
        #expect(results.map(\.ref) == ["add"])
    }

    @Test func activeTextInputIsDiscoverableEvenWhenPlatformVisibilityIsFalse() {
        let snapshot = LoupeSnapshot(
            id: "active-search-field-surface-visibility",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 402, height: 874), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": Self.node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 402, height: 874),
                    children: ["content", "search"]
                ),
                "content": Self.node(
                    ref: "content",
                    parentRef: "app",
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 402, height: 874),
                    backgroundAlpha: 1
                ),
                "search": Self.node(
                    ref: "search",
                    parentRef: "app",
                    typeName: "UISearchBarTextField",
                    role: "textField",
                    text: "Invoice",
                    placeholder: "Search",
                    frame: LoupeRect(x: 33, y: 803, width: 276, height: 38),
                    isVisible: false,
                    isInteractive: true,
                    uiKit: Self.uiKitTextField(className: "UISearchBarTextField", isFirstResponder: true)
                ),
            ]
        )

        let queryResults = LoupeSnapshotQuery.find(.text("Invoice"), in: snapshot)
        #expect(queryResults.map(\.ref) == ["search"])
        #expect(queryResults.first?.isVisible == true)

        let textFieldResults = LoupeSnapshotQuery.find(.role("textField"), in: snapshot)
        #expect(textFieldResults.map(\.ref) == ["search"])

        let compact = LoupeObservationCompactor.compact(snapshot)
        #expect(compact.visibleTexts.map(\.ref).contains("search"))
        #expect(compact.visibleTexts.map(\.text).contains("Invoice"))

        let screenMap = LoupeScreenMapper.map(snapshot)
        #expect(screenMap.elements.map(\.ref).contains("search"))
    }

    private static func presentedScreenSnapshot() -> LoupeSnapshot {
        LoupeSnapshot(
            id: "surface-visibility",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 440, height: 956), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    children: ["oldRoot", "newRoot", "transparentOverlay"]
                ),
                "oldRoot": node(
                    ref: "oldRoot",
                    parentRef: "app",
                    typeName: "UITransitionView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    backgroundAlpha: 1,
                    children: ["oldTitle", "oldButton"]
                ),
                "oldTitle": node(
                    ref: "oldTitle",
                    parentRef: "oldRoot",
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Your Profit..!",
                    frame: LoupeRect(x: 0, y: 420, width: 440, height: 26)
                ),
                "oldButton": node(
                    ref: "oldButton",
                    parentRef: "oldRoot",
                    typeName: "UIButton",
                    role: "button",
                    text: "Get Started",
                    frame: LoupeRect(x: 80, y: 744, width: 280, height: 50),
                    isInteractive: true
                ),
                "newRoot": node(
                    ref: "newRoot",
                    parentRef: "app",
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    backgroundAlpha: 1,
                    children: ["loginTitle", "usernameField", "loginButton"]
                ),
                "loginTitle": node(
                    ref: "loginTitle",
                    parentRef: "newRoot",
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Login",
                    frame: LoupeRect(x: 20, y: 392, width: 400, height: 50)
                ),
                "usernameField": node(
                    ref: "usernameField",
                    parentRef: "newRoot",
                    typeName: "UITextField",
                    role: "textField",
                    placeholder: "Enter Username",
                    frame: LoupeRect(x: 81, y: 457, width: 309, height: 50),
                    isInteractive: true
                ),
                "loginButton": node(
                    ref: "loginButton",
                    parentRef: "newRoot",
                    typeName: "UIButton",
                    role: "button",
                    text: "Login",
                    frame: LoupeRect(x: 90, y: 661, width: 260, height: 50),
                    isInteractive: true
                ),
                "transparentOverlay": node(
                    ref: "transparentOverlay",
                    parentRef: "app",
                    typeName: "UIEditingOverlayGestureView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    isInteractive: true
                ),
            ]
        )
    }

    private static func alertSnapshot() -> LoupeSnapshot {
        LoupeSnapshot(
            id: "alert-surface-visibility",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 440, height: 956), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": node(
                    ref: "app",
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    children: ["content", "transition"]
                ),
                "content": node(
                    ref: "content",
                    parentRef: "app",
                    testID: "example.components",
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    backgroundAlpha: 1,
                    children: ["underlyingButton"]
                ),
                "underlyingButton": node(
                    ref: "underlyingButton",
                    parentRef: "content",
                    typeName: "UIButton",
                    role: "button",
                    text: "Show Alert",
                    frame: LoupeRect(x: 20, y: 469, width: 400, height: 44),
                    backgroundAlpha: 0.16,
                    isInteractive: true
                ),
                "transition": node(
                    ref: "transition",
                    parentRef: "app",
                    typeName: "UITransitionView",
                    frame: LoupeRect(x: 0, y: 0, width: 440, height: 956),
                    children: ["alert"]
                ),
                "alert": node(
                    ref: "alert",
                    parentRef: "transition",
                    testID: "example.components.alert",
                    typeName: "_UIAlertControllerPhoneTVMacView",
                    semanticText: "UIKit Alert Inspectable alert fixture Close",
                    frame: LoupeRect(x: 60, y: 416, width: 320, height: 152),
                    children: ["alertContent"]
                ),
                "alertContent": node(
                    ref: "alertContent",
                    parentRef: "alert",
                    typeName: "UIView",
                    semanticText: "UIKit Alert Inspectable alert fixture Close",
                    frame: LoupeRect(x: 60, y: 416, width: 320, height: 152)
                ),
            ]
        )
    }

    private static func node(
        ref: String,
        parentRef: String? = nil,
        kind: LoupeNodeKind = .view,
        testID: String? = nil,
        typeName: String,
        role: String? = nil,
        text: String? = nil,
        placeholder: String? = nil,
        semanticText: String? = nil,
        frame: LoupeRect,
        backgroundAlpha: Double? = nil,
        isVisible: Bool = true,
        isInteractive: Bool = false,
        accessibility: LoupeAccessibility? = nil,
        uiKit: LoupeUIKitProperties? = nil,
        custom: [String: LoupeMetadataValue] = [:],
        children: [String] = []
    ) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: parentRef,
            kind: kind,
            typeName: typeName,
            role: role,
            testID: testID,
            placeholder: placeholder,
            text: text,
            semanticText: semanticText,
            frame: frame,
            isVisible: isVisible,
            isEnabled: true,
            isInteractive: isInteractive,
            style: backgroundAlpha.map {
                LoupeStyle(backgroundColor: LoupeColor(red: 1, green: 1, blue: 1, alpha: $0))
            },
            accessibility: accessibility,
            uiKit: uiKit,
            custom: custom,
            children: children
        )
    }

    private static func uiKitTextField(className: String, isFirstResponder: Bool) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: false,
            clipsToBounds: false,
            userInteractionEnabled: true,
            isFirstResponder: isFirstResponder,
            textField: LoupeUITextFieldProperties(
                textAlignment: "left",
                borderStyle: "none",
                isSecureTextEntry: false
            )
        )
    }

    private static func uiKitScrollView() -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: "UITableView",
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: true,
            clipsToBounds: true,
            userInteractionEnabled: true,
            isFirstResponder: false,
            scrollView: LoupeUIScrollViewProperties(
                contentOffset: LoupePoint(x: 0, y: 0),
                contentSize: LoupeSize(width: 390, height: 1200),
                adjustedContentInset: LoupeInsets(top: 0, left: 0, bottom: 0, right: 0),
                isScrollEnabled: true,
                alwaysBounceVertical: true,
                alwaysBounceHorizontal: false
            )
        )
    }
}
