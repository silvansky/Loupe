import Foundation
import Testing
@testable import LoupeCore

struct LayoutAuditTests {
    @Test func auditReportsOverlappingSiblingsAndChildrenOutsideParents() {
        let snapshot = LoupeSnapshot(
            id: "layout-1",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    testID: "root",
                    frame: LoupeRect(x: 0, y: 0, width: 200, height: 200),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["a", "b", "c"]
                ),
                "a": LoupeNode(
                    ref: "a",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.a",
                    frame: LoupeRect(x: 20, y: 20, width: 80, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "b": LoupeNode(
                    ref: "b",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.b",
                    frame: LoupeRect(x: 60, y: 60, width: 80, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "c": LoupeNode(
                    ref: "c",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "card.c",
                    frame: LoupeRect(x: 180, y: 180, width: 60, height: 60),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issueCount == 2)
        #expect(audit.issues.contains { $0.kind == .overlappingSiblings })
        #expect(audit.issues.contains { $0.kind == .childOutsideParent })
    }

    @Test func auditReportsInteractiveTargetAndTestIDIssues() {
        let snapshot = LoupeSnapshot(
            id: "layout-2",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["small", "missing", "duplicate-a", "duplicate-b", "image-a", "image-b"]
                ),
                "small": button(ref: "small", testID: "small.button", frame: LoupeRect(x: 20, y: 20, width: 30, height: 30)),
                "missing": button(ref: "missing", testID: nil, frame: LoupeRect(x: 20, y: 80, width: 80, height: 44)),
                "duplicate-a": button(ref: "duplicate-a", testID: "duplicate.button", frame: LoupeRect(x: 20, y: 140, width: 80, height: 44)),
                "duplicate-b": button(ref: "duplicate-b", testID: "duplicate.button", frame: LoupeRect(x: 120, y: 140, width: 80, height: 44)),
                "image-a": decorativeImage(ref: "image-a", testID: "chevron.right", frame: LoupeRect(x: 20, y: 210, width: 12, height: 16)),
                "image-b": decorativeImage(ref: "image-b", testID: "chevron.right", frame: LoupeRect(x: 120, y: 210, width: 12, height: 16)),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.testID == "small.button" })
        #expect(audit.issues.contains { $0.kind == .missingTestID && $0.ref == "missing" })
        #expect(audit.issues.filter { $0.kind == .duplicateTestID }.count == 2)
        #expect(!audit.issues.contains { $0.kind == .duplicateTestID && $0.testID == "chevron.right" })
    }

    @Test func auditIgnoresDecorativeImageDuplicateAndOverlapNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-3",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["card", "shadow-a", "shadow-b"]
                ),
                "card": LoupeNode(
                    ref: "card",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "book.card",
                    frame: LoupeRect(x: 20, y: 80, width: 120, height: 180),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "shadow-a": decorativeImage(
                    ref: "shadow-a",
                    testID: "/tmp/App.app/left-shadow.png",
                    frame: LoupeRect(x: 24, y: 80, width: 24, height: 180)
                ),
                "shadow-b": decorativeImage(
                    ref: "shadow-b",
                    testID: "/tmp/App.app/left-shadow.png",
                    frame: LoupeRect(x: 220, y: 80, width: 24, height: 180)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .duplicateTestID && $0.testID == "/tmp/App.app/left-shadow.png" })
        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings })
    }

    @Test func auditIgnoresHiddenDuplicateTestIDs() {
        let snapshot = LoupeSnapshot(
            id: "layout-hidden-duplicates",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["visible", "hidden-a", "hidden-b"]
                ),
                "visible": LoupeNode(
                    ref: "visible",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "settings.row",
                    frame: LoupeRect(x: 20, y: 20, width: 120, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "hidden-a": LoupeNode(
                    ref: "hidden-a",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "hidden.row",
                    frame: LoupeRect(x: 20, y: 80, width: 120, height: 44),
                    isVisible: false,
                    isEnabled: true,
                    isInteractive: false
                ),
                "hidden-b": LoupeNode(
                    ref: "hidden-b",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "hidden.row",
                    frame: LoupeRect(x: 20, y: 140, width: 120, height: 44),
                    isVisible: false,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .duplicateTestID && $0.testID == "hidden.row" })
    }

    @Test func auditIgnoresVisibleButOffscreenNodes() {
        let snapshot = LoupeSnapshot(
            id: "layout-offscreen-visible",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["onscreen-small", "dismissed-button"]
                ),
                "onscreen-small": button(
                    ref: "onscreen-small",
                    testID: "visible.small",
                    frame: LoupeRect(x: 20, y: 20, width: 30, height: 30)
                ),
                "dismissed-button": button(
                    ref: "dismissed-button",
                    testID: nil,
                    frame: LoupeRect(x: 300, y: 888, width: 77, height: 31)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "onscreen-small" })
        #expect(!audit.issues.contains { $0.ref == "dismissed-button" })
    }

    @Test func auditIgnoresSyntheticAndSystemTabBarSmallTargetNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-tabbar-noise",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 1920, height: 1080), scale: 2),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 1920, height: 1080),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["tab-button", "synthetic-tab-item", "app-button"]
                ),
                "tab-button": tabBarButton(ref: "tab-button"),
                "synthetic-tab-item": tabBarButton(
                    ref: "synthetic-tab-item",
                    typeName: "UITabBarItem",
                    role: "button",
                    text: "Latest",
                    custom: ["synthetic": .bool(true), "source": .string("UITabBarItem")]
                ),
                "app-button": button(
                    ref: "app-button",
                    testID: "app.small",
                    frame: LoupeRect(x: 100, y: 200, width: 30, height: 30)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.testID == "app.small" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "tab-button" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "synthetic-tab-item" })
    }

    @Test func auditIgnoresSystemTabBarItemOverlapNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-tabbar-overlap-noise",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UITabBar",
                    role: "tabBar",
                    frame: LoupeRect(x: 0, y: 760, width: 390, height: 84),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["home", "discover", "app-a", "app-b"]
                ),
                "home": tabBarButton(
                    ref: "home",
                    typeName: "UITabBarItem",
                    role: "button",
                    text: "Home",
                    frame: LoupeRect(x: 20, y: 776, width: 95, height: 54),
                    custom: ["synthetic": .bool(true), "source": .string("UITabBarItem")]
                ),
                "discover": tabBarButton(
                    ref: "discover",
                    typeName: "UITabBarItem",
                    role: "button",
                    text: "Discover",
                    frame: LoupeRect(x: 106, y: 776, width: 95, height: 54),
                    custom: ["synthetic": .bool(true), "source": .string("UITabBarItem")]
                ),
                "app-a": button(
                    ref: "app-a",
                    testID: "app.a",
                    frame: LoupeRect(x: 40, y: 40, width: 80, height: 44)
                ),
                "app-b": button(
                    ref: "app-b",
                    testID: "app.b",
                    frame: LoupeRect(x: 80, y: 40, width: 80, height: 44)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "home" })
        #expect(audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "app-a" })
    }

    @Test func auditIgnoresScrollContainerAndTextFieldPlaceholderNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-search-noise",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(backgroundColor: LoupeColor(red: 1, green: 1, blue: 1, alpha: 1)),
                    children: [
                        "thin-scroll",
                        "search-field",
                        "scope-control",
                        "text-canvas",
                        "low-contrast-title",
                    ]
                ),
                "thin-scroll": LoupeNode(
                    ref: "thin-scroll",
                    parentRef: "root",
                    kind: .view,
                    typeName: "HostingScrollView",
                    role: "scrollView",
                    frame: LoupeRect(x: 0, y: 180, width: 390, height: 16),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: scrollViewProperties(className: "HostingScrollView", contentSize: LoupeSize(width: 390, height: 16))
                ),
                "search-field": LoupeNode(
                    ref: "search-field",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UISearchBarTextField",
                    role: "textField",
                    text: "Movies, Shows, People",
                    frame: LoupeRect(x: 16, y: 100, width: 358, height: 38),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: textFieldProperties(className: "UISearchBarTextField"),
                    children: ["placeholder"]
                ),
                "scope-control": LoupeNode(
                    ref: "scope-control",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UISegmentedControl",
                    role: "segmentedControl",
                    text: "All Movies Series People",
                    frame: LoupeRect(x: 16, y: 160, width: 358, height: 32),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: segmentedControlProperties(className: "UISegmentedControl")
                ),
                "text-canvas": LoupeNode(
                    ref: "text-canvas",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UITextLayoutCanvasView",
                    frame: LoupeRect(x: 55, y: 72, width: 232, height: 40),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: plainUIKitProperties(className: "_UITextLayoutCanvasView"),
                    children: ["text-fragment"]
                ),
                "text-fragment": LoupeNode(
                    ref: "text-fragment",
                    parentRef: "text-canvas",
                    kind: .view,
                    typeName: "_UITextLayoutFragmentView",
                    frame: LoupeRect(x: 47, y: 81, width: 81, height: 22),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: plainUIKitProperties(className: "_UITextLayoutFragmentView")
                ),
                "placeholder": LoupeNode(
                    ref: "placeholder",
                    parentRef: "search-field",
                    kind: .view,
                    typeName: "UISearchBarTextFieldLabel",
                    role: "staticText",
                    text: "Movies, Shows, People",
                    frame: LoupeRect(x: 55, y: 112, width: 174, height: 20),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(textColor: LoupeColor(red: 0.24, green: 0.24, blue: 0.24, alpha: 0.6)),
                    uiKit: labelProperties(className: "UISearchBarTextFieldLabel")
                ),
                "low-contrast-title": LoupeNode(
                    ref: "low-contrast-title",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Low contrast",
                    frame: LoupeRect(x: 16, y: 220, width: 160, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(textColor: LoupeColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)),
                    uiKit: labelProperties(className: "UILabel")
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "thin-scroll" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "search-field" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "scope-control" })
        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "text-fragment" })
        #expect(!audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "placeholder" })
        #expect(audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "low-contrast-title" })
    }

    @Test func auditIgnoresPassiveAppKitImageElementSmallTargetNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-passive-image-noise",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 1920, height: 1080), scale: 2),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "NSView",
                    frame: LoupeRect(x: 0, y: 0, width: 1920, height: 1080),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["passive-image", "gesture-image"]
                ),
                "passive-image": appKitImageView(
                    ref: "passive-image",
                    frame: LoupeRect(x: 100, y: 100, width: 32, height: 32),
                    gestureRecognizers: []
                ),
                "gesture-image": appKitImageView(
                    ref: "gesture-image",
                    frame: LoupeRect(x: 160, y: 100, width: 32, height: 32),
                    gestureRecognizers: ["NSClickGestureRecognizer"]
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "passive-image" })
        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "gesture-image" })
    }

    @Test func auditAllowsScrollContentAndFocusDecorationsOutsideParentBounds() {
        let snapshot = LoupeSnapshot(
            id: "layout-scroll-focus-noise",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 1920, height: 1080), scale: 2),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 1920, height: 1080),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["table", "focus-parent"]
                ),
                "table": LoupeNode(
                    ref: "table",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableView",
                    role: "tableView",
                    frame: LoupeRect(x: 0, y: 0, width: 880, height: 1080),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: tableViewProperties(className: "UITableView"),
                    children: ["table-content"]
                ),
                "table-content": LoupeNode(
                    ref: "table-content",
                    parentRef: "table",
                    kind: .view,
                    typeName: "UITableViewWrapperView",
                    role: "scrollView",
                    frame: LoupeRect(x: 80, y: 157, width: 800, height: 4096),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: tableViewProperties(className: "UITableViewWrapperView")
                ),
                "focus-parent": LoupeNode(
                    ref: "focus-parent",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIFloatingContentTransformView",
                    frame: LoupeRect(x: 80, y: 157, width: 800, height: 112),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: plainUIKitProperties(className: "_UIFloatingContentTransformView"),
                    children: ["focus-halo"]
                ),
                "focus-halo": LoupeNode(
                    ref: "focus-halo",
                    parentRef: "focus-parent",
                    kind: .view,
                    typeName: "_UIFloatingContentCornerRadiusAnimatingView",
                    frame: LoupeRect(x: 76, y: 153, width: 808, height: 120),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: plainUIKitProperties(className: "_UIFloatingContentCornerRadiusAnimatingView")
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "table-content" })
        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "focus-halo" })
    }

    @Test func auditIgnoresUnidentifiedBackgroundLayerOverlap() {
        let snapshot = LoupeSnapshot(
            id: "layout-4",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["background", "title"]
                ),
                "background": LoupeNode(
                    ref: "background",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 20, y: 80, width: 200, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    text: "Reading Now",
                    frame: LoupeRect(x: 40, y: 100, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings })
    }

    @Test func auditIgnoresLoupeProbeOverlapNoise() {
        let snapshot = LoupeSnapshot(
            id: "watch-probe-overlap",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 208, height: 248), scale: 2),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "WKApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 208, height: 248),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["form", "button"]
                ),
                "form": LoupeNode(
                    ref: "form",
                    parentRef: "root",
                    kind: .view,
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    testID: "safetimer.addForm",
                    text: "Add timer form",
                    frame: LoupeRect(x: 2, y: 62, width: 204, height: 150),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    custom: ["loupe.probe": .bool(true)]
                ),
                "button": LoupeNode(
                    ref: "button",
                    parentRef: "root",
                    kind: .view,
                    typeName: "LoupeWatchProbe",
                    role: "group",
                    testID: "safetimer.addForm.saveButton",
                    text: "Save timer button",
                    frame: LoupeRect(x: 15, y: 184.6, width: 178, height: 52.5),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    custom: ["loupe.probe": .bool(true)]
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings })
    }

    @Test func auditIgnoresLoupeProbeContainmentNoise() {
        let snapshot = LoupeSnapshot(
            id: "probe-containment",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 800, height: 850), scale: 1),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    role: "application",
                    frame: LoupeRect(x: 0, y: 0, width: 800, height: 850),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["probe"]
                ),
                "probe": LoupeNode(
                    ref: "probe",
                    parentRef: "root",
                    kind: .view,
                    typeName: "LoupeRegisteredProbe",
                    role: "button",
                    testID: "openimmersive.enterStreamURL",
                    text: "Enter Stream URL",
                    frame: LoupeRect(x: 725.25, y: 526.25, width: 207.5, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    custom: ["loupe.probe": .bool(true)]
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent })
    }

    private func button(ref: String, testID: String?, frame: LoupeRect) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "UIButton",
            role: "button",
            testID: testID,
            frame: frame,
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
        )
    }

    private func decorativeImage(ref: String, testID: String, frame: LoupeRect) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "UIImageView",
            role: "image",
            testID: testID,
            label: "Forward",
            frame: frame,
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            accessibility: LoupeAccessibility(
                identifier: testID,
                label: "Forward",
                traits: ["image"],
                frame: frame,
                isElement: false
            ),
            uiKit: LoupeUIKitProperties(
                className: "UIImageView",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: false,
                isFirstResponder: false
            )
        )
    }

    private func appKitImageView(
        ref: String,
        frame: LoupeRect,
        gestureRecognizers: [String]
    ) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: "ImageView",
            role: "image",
            frame: frame,
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            accessibility: LoupeAccessibility(
                label: "Solar",
                traits: ["image"],
                frame: frame,
                isElement: true
            ),
            uiKit: LoupeUIKitProperties(
                className: "ImageView",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                gestureRecognizers: gestureRecognizers,
                isFirstResponder: false,
                control: LoupeUIControlProperties(controlState: "enabled", controlEvents: [])
            )
        )
    }

    private func tabBarButton(
        ref: String,
        typeName: String = "UITabBarButton",
        role: String? = nil,
        text: String? = nil,
        frame: LoupeRect = LoupeRect(x: 986, y: 64, width: 100, height: 32),
        custom: [String: LoupeMetadataValue] = [:]
    ) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: "root",
            kind: .view,
            typeName: typeName,
            role: role,
            text: text,
            frame: frame,
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            uiKit: LoupeUIKitProperties(
                className: "UITabBarButton",
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: false,
                canBecomeFocused: true,
                control: LoupeUIControlProperties(controlState: "normal", controlEvents: ["primaryActionTriggered"])
            ),
            custom: custom
        )
    }

    private func tableViewProperties(className: String) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: true,
            clipsToBounds: className == "UITableView",
            userInteractionEnabled: true,
            isFirstResponder: false,
            scrollView: LoupeUIScrollViewProperties(
                contentOffset: LoupePoint(x: 0, y: -157),
                contentSize: LoupeSize(width: 880, height: 4096),
                adjustedContentInset: LoupeInsets(top: 157, left: 0, bottom: 60, right: 0),
                isScrollEnabled: true,
                alwaysBounceVertical: true,
                alwaysBounceHorizontal: false
            ),
            tableView: LoupeUITableViewProperties(
                rowHeight: -1,
                estimatedRowHeight: -1,
                usesAutomaticRowHeight: true,
                usesEstimatedRowHeight: false,
                delegateRespondsToHeightForRowAt: false,
                delegateRespondsToEstimatedHeightForRowAt: false
            )
        )
    }

    private func scrollViewProperties(className: String, contentSize: LoupeSize) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: true,
            clipsToBounds: true,
            userInteractionEnabled: true,
            isFirstResponder: false,
            scrollView: LoupeUIScrollViewProperties(
                contentOffset: LoupePoint(x: 0, y: 0),
                contentSize: contentSize,
                adjustedContentInset: LoupeInsets(top: 0, left: 0, bottom: 0, right: 0),
                isScrollEnabled: true,
                alwaysBounceVertical: false,
                alwaysBounceHorizontal: false
            )
        )
    }

    private func textFieldProperties(className: String) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: false,
            clipsToBounds: false,
            userInteractionEnabled: true,
            isFirstResponder: false,
            textField: LoupeUITextFieldProperties()
        )
    }

    private func segmentedControlProperties(className: String) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: false,
            clipsToBounds: true,
            userInteractionEnabled: true,
            isFirstResponder: false,
            control: LoupeUIControlProperties(controlState: "normal", controlEvents: ["valueChanged"]),
            segmentedControl: LoupeUISegmentedControlProperties(
                selectedSegmentIndex: 0,
                segments: ["All", "Movies", "Series", "People"]
            )
        )
    }

    private func labelProperties(className: String) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: false,
            clipsToBounds: false,
            userInteractionEnabled: false,
            isFirstResponder: false,
            label: LoupeUILabelProperties()
        )
    }

    private func plainUIKitProperties(className: String) -> LoupeUIKitProperties {
        LoupeUIKitProperties(
            className: className,
            tag: 0,
            alpha: 1,
            isHidden: false,
            isOpaque: false,
            clipsToBounds: false,
            userInteractionEnabled: true,
            isFirstResponder: false
        )
    }
}
