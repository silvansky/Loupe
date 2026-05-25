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

    @Test func auditIgnoresDuplicateTestIDWhenTargetsShareFrame() {
        let frame = LoupeRect(x: 20, y: 140, width: 80, height: 44)
        let snapshot = LoupeSnapshot(
            id: "layout-same-target-duplicates",
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
                    children: ["duplicate-a", "duplicate-b", "distinct"]
                ),
                "duplicate-a": button(ref: "duplicate-a", testID: "shared.target", frame: frame),
                "duplicate-b": button(ref: "duplicate-b", testID: "shared.target", frame: frame),
                "distinct": button(ref: "distinct", testID: "shared.target", frame: LoupeRect(x: 140, y: 140, width: 80, height: 44)),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.filter { $0.kind == .duplicateTestID && $0.testID == "shared.target" }.count == 3)
    }

    @Test func auditIgnoresSameFrameDuplicateTestIDWithoutAmbiguousTargets() {
        let frame = LoupeRect(x: 20, y: 140, width: 80, height: 44)
        let snapshot = LoupeSnapshot(
            id: "layout-same-frame-duplicates",
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
                    children: ["duplicate-a", "duplicate-b"]
                ),
                "duplicate-a": button(ref: "duplicate-a", testID: "same.frame.target", frame: frame),
                "duplicate-b": button(ref: "duplicate-b", testID: "same.frame.target", frame: frame),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .duplicateTestID && $0.testID == "same.frame.target" })
    }

    @Test func auditIgnoresSystemGeneratedDuplicateTestIDs() {
        let snapshot = LoupeSnapshot(
            id: "layout-system-testids",
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
                    children: ["grabber-a", "grabber-b"]
                ),
                "grabber-a": button(
                    ref: "grabber-a",
                    testID: "com.apple.text.grabber.leading",
                    frame: LoupeRect(x: 80, y: 40, width: 10, height: 10)
                ),
                "grabber-b": button(
                    ref: "grabber-b",
                    testID: "com.apple.text.grabber.leading",
                    frame: LoupeRect(x: 120, y: 40, width: 10, height: 10)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .duplicateTestID && $0.testID == "com.apple.text.grabber.leading" })
    }

    @Test func auditIgnoresSmallPrivateUIKitImplementationControls() {
        let snapshot = LoupeSnapshot(
            id: "layout-private-controls",
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
                    children: ["public-small", "cell-accessory", "nav-title"]
                ),
                "public-small": button(
                    ref: "public-small",
                    testID: "small.public",
                    frame: LoupeRect(x: 20, y: 20, width: 30, height: 30)
                ),
                "cell-accessory": privateUIKitControl(
                    ref: "cell-accessory",
                    typeName: "_UITableCellAccessoryButton",
                    frame: LoupeRect(x: 370, y: 80, width: 10, height: 14)
                ),
                "nav-title": privateUIKitControl(
                    ref: "nav-title",
                    typeName: "_UINavigationBarTitleControl",
                    frame: LoupeRect(x: 150, y: 44, width: 80, height: 21)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "public-small" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "cell-accessory" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "nav-title" })
    }

    @Test func auditIgnoresSystemOwnedCellAccessoryButtonsWithoutClassNameRules() {
        let snapshot = LoupeSnapshot(
            id: "layout-system-cell-accessory",
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
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Basic Example",
                    frame: LoupeRect(x: 20, y: 120, width: 350, height: 53),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["accessory"]
                ),
                "accessory": LoupeNode(
                    ref: "accessory",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "ConflictingUserClassName",
                    role: "button",
                    frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    accessibility: LoupeAccessibility(
                        traits: [],
                        frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
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
                    frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
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

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.ref == "accessory" })
    }

    @Test func auditKeepsCustomCellAccessoryButtonsEvenWithSystemClassNames() {
        let snapshot = LoupeSnapshot(
            id: "layout-custom-cell-accessory",
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
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableViewCell",
                    role: "cell",
                    text: "Basic Example",
                    frame: LoupeRect(x: 20, y: 120, width: 350, height: 53),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.example.App"),
                    children: ["accessory"]
                ),
                "accessory": LoupeNode(
                    ref: "accessory",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "_UITableCellAccessoryButton",
                    role: "button",
                    frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    accessibility: LoupeAccessibility(
                        traits: [],
                        frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
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
                    frame: LoupeRect(x: 350, y: 140, width: 10.33, height: 14),
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

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .missingTestID && $0.ref == "accessory" })
        #expect(audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "accessory" })
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

    @Test func auditIgnoresScrollContentAndPrivateChromeContainmentNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-scroll-private",
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
                    children: ["table", "nav", "animation-parent"]
                ),
                "table": LoupeNode(
                    ref: "table",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UITableView",
                    role: "tableView",
                    frame: LoupeRect(x: 0, y: 100, width: 390, height: 400),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["partly-visible-cell"]
                ),
                "partly-visible-cell": LoupeNode(
                    ref: "partly-visible-cell",
                    parentRef: "table",
                    kind: .view,
                    typeName: "UITableViewCell",
                    frame: LoupeRect(x: 0, y: 470, width: 390, height: 80),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
                "nav": LoupeNode(
                    ref: "nav",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UINavigationBar",
                    role: "navigationBar",
                    frame: LoupeRect(x: 0, y: 44, width: 390, height: 54),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["bar-background"]
                ),
                "bar-background": privateUIKitControl(
                    ref: "bar-background",
                    typeName: "_UIBarBackground",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 98),
                    parentRef: "nav",
                    role: nil,
                    isInteractive: false
                ),
                "animation-parent": LoupeNode(
                    ref: "animation-parent",
                    parentRef: "root",
                    kind: .view,
                    typeName: "AnimationView",
                    frame: LoupeRect(x: 212.33, y: 62, width: 173.67, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["animation-child"]
                ),
                "animation-child": LoupeNode(
                    ref: "animation-child",
                    parentRef: "animation-parent",
                    kind: .view,
                    typeName: "AnimationView",
                    frame: LoupeRect(x: 204.05, y: 59.9, width: 190.24, height: 48.2),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore")
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "partly-visible-cell" })
        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "bar-background" })
        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "animation-child" })
    }

    @Test func auditIgnoresMinorContainmentOverhang() {
        let snapshot = LoupeSnapshot(
            id: "layout-minor-overhang",
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
                    children: ["parent"]
                ),
                "parent": LoupeNode(
                    ref: "parent",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 10, y: 72, width: 320, height: 82.33),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["child"]
                ),
                "child": LoupeNode(
                    ref: "child",
                    parentRef: "parent",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 10, y: 72, width: 333, height: 82.67),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "child" })
    }

    @Test func auditIgnoresOffscreenVisibleTextAndContainmentNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-offscreen-text",
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
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 8, y: 80, width: 360, height: 120),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["offscreen-time"]
                ),
                "offscreen-time": LoupeNode(
                    ref: "offscreen-time",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "InsetLabel",
                    text: "Fri, 12 Jun, 6:32 PM",
                    frame: LoupeRect(x: 390, y: 120, width: 120, height: 12),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(
                        backgroundColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 0),
                        textColor: LoupeColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1)
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.ref == "offscreen-time" })
    }

    @Test func auditClipsContainmentChecksToTheScreenBounds() {
        let snapshot = LoupeSnapshot(
            id: "layout-screen-clipped-containment",
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
                    children: ["input-bar"]
                ),
                "input-bar": LoupeNode(
                    ref: "input-bar",
                    parentRef: "root",
                    kind: .view,
                    typeName: "InputBarAccessoryView",
                    frame: LoupeRect(x: 0, y: 800, width: 390, height: 44),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["input-content"]
                ),
                "input-content": LoupeNode(
                    ref: "input-content",
                    parentRef: "input-bar",
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 800, width: 390, height: 90),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "input-content" })
    }

    @Test func auditIgnoresMinorSiblingOverlapAndScrollTargetSizeNoise() {
        let snapshot = LoupeSnapshot(
            id: "layout-minor-overlap-scroll",
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
                    children: ["first", "second", "language-strip"]
                ),
                "first": button(ref: "first", testID: "first", frame: LoupeRect(x: 10, y: 20, width: 74, height: 54)),
                "second": button(ref: "second", testID: "second", frame: LoupeRect(x: 77, y: 20, width: 74, height: 54)),
                "language-strip": LoupeNode(
                    ref: "language-strip",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIScrollView",
                    role: "scrollView",
                    frame: LoupeRect(x: 0, y: 90, width: 329, height: 38),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "first" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "language-strip" })
    }

    @Test func auditDoesNotUseWindowBackgroundForContrast() {
        let snapshot = LoupeSnapshot(
            id: "layout-window-background",
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 390, height: 844), scale: 3),
            rootRefs: ["app"],
            nodes: [
                "app": LoupeNode(
                    ref: "app",
                    parentRef: nil,
                    kind: .application,
                    typeName: "UIApplication",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["window"]
                ),
                "window": LoupeNode(
                    ref: "window",
                    parentRef: "app",
                    kind: .window,
                    typeName: "UIWindow",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(backgroundColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1)),
                    children: ["wrapper"]
                ),
                "wrapper": LoupeNode(
                    ref: "wrapper",
                    parentRef: "window",
                    kind: .view,
                    typeName: "_UINavigationBarTitleControl",
                    frame: LoupeRect(x: 120, y: 60, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["title"]
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "wrapper",
                    kind: .view,
                    typeName: "UILabel",
                    text: "Examples",
                    frame: LoupeRect(x: 120, y: 60, width: 120, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(
                        backgroundColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 0),
                        textColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1)
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "title" })
    }

    @Test func auditIgnoresIntentionalModalOverlayOverlap() {
        let snapshot = LoupeSnapshot(
            id: "layout-modal-overlay",
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
                    children: ["content", "alert"]
                ),
                "content": LoupeNode(
                    ref: "content",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UIView",
                    testID: "screen.content",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["behind-button"]
                ),
                "behind-button": LoupeNode(
                    ref: "behind-button",
                    parentRef: "content",
                    kind: .view,
                    typeName: "UIButton",
                    role: "button",
                    frame: LoupeRect(x: 20, y: 60, width: 30, height: 30),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true
                ),
                "alert": LoupeNode(
                    ref: "alert",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIAlertControllerPhoneTVMacView",
                    text: "Reply Forward Cancel",
                    frame: LoupeRect(x: 35, y: 280, width: 320, height: 280),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: LoupeUIKitProperties(
                        viewControllerRole: "alert",
                        className: "_UIAlertControllerPhoneTVMacView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "content" })
        #expect(!audit.issues.contains { $0.kind == .smallInteractiveTarget && $0.ref == "behind-button" })
        #expect(!audit.issues.contains { $0.kind == .missingTestID && $0.ref == "behind-button" })
    }

    @Test func auditIgnoresAppleModalBackdropOverlapByRuntimeAndAlertRole() {
        let snapshot = LoupeSnapshot(
            id: "layout-modal-popover-backdrop",
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
                    children: ["backdrop", "popover"]
                ),
                "backdrop": LoupeNode(
                    ref: "backdrop",
                    parentRef: "root",
                    kind: .view,
                    typeName: "ProjectBackdropName",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore")
                ),
                "popover": LoupeNode(
                    ref: "popover",
                    parentRef: "root",
                    kind: .view,
                    typeName: "ProjectPopoverName",
                    semanticText: "Delete Report",
                    frame: LoupeRect(x: 110, y: 125, width: 250, height: 136),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    children: ["alert"]
                ),
                "alert": LoupeNode(
                    ref: "alert",
                    parentRef: "popover",
                    kind: .view,
                    typeName: "ProjectAlertName",
                    frame: LoupeRect(x: 110, y: 125, width: 240, height: 136),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
                    uiKit: LoupeUIKitProperties(
                        viewControllerRole: "alert",
                        className: "ProjectAlertName",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "backdrop" })
    }

    @Test func auditDoesNotTreatUserNamedModalClassesAsSystemOverlay() {
        let snapshot = LoupeSnapshot(
            id: "layout-user-named-modal-classes",
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
                    children: ["backdrop", "popover"]
                ),
                "backdrop": LoupeNode(
                    ref: "backdrop",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIPopoverDimmingView",
                    frame: LoupeRect(x: 0, y: 0, width: 390, height: 844),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "_UIPopoverDimmingView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    )
                ),
                "popover": LoupeNode(
                    ref: "popover",
                    parentRef: "root",
                    kind: .view,
                    typeName: "_UIAlertControllerPhoneTVMacView",
                    semanticText: "Delete Report",
                    frame: LoupeRect(x: 110, y: 125, width: 250, height: 136),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    uiKit: LoupeUIKitProperties(
                        className: "_UIAlertControllerPhoneTVMacView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: false,
                        isFirstResponder: false
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "backdrop" })
    }

    @Test func auditIgnoresSwipeActionExpansionLayout() {
        let snapshot = LoupeSnapshot(
            id: "layout-swipe-actions",
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
                    children: ["cell"]
                ),
                "cell": LoupeNode(
                    ref: "cell",
                    parentRef: "root",
                    kind: .view,
                    typeName: "MailCell",
                    role: "cell",
                    text: "Apple News",
                    frame: LoupeRect(x: -222, y: 204, width: 402, height: 97),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    children: ["actions"]
                ),
                "actions": LoupeNode(
                    ref: "actions",
                    parentRef: "cell",
                    kind: .view,
                    typeName: "SwipeActionsView",
                    text: "More Flag Trash",
                    frame: LoupeRect(x: 180, y: 204, width: 804, height: 97),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["more", "flag", "trash"]
                ),
                "more": swipeActionWrapper(ref: "more", parentRef: "actions", text: "More", x: 180),
                "flag": swipeActionWrapper(ref: "flag", parentRef: "actions", text: "Flag", x: 254),
                "trash": swipeActionWrapper(ref: "trash", parentRef: "actions", text: "Trash", x: 328),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && $0.ref == "actions" })
        #expect(!audit.issues.contains { $0.kind == .childOutsideParent && ["more", "flag", "trash"].contains($0.ref) })
        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && ["more", "flag", "trash"].contains($0.ref) })
    }

    @Test func auditUsesStructuredBarItemKindInsteadOfClassName() {
        let snapshot = LoupeSnapshot(
            id: "layout-structured-bar-kind",
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
                    children: ["title", "item"]
                ),
                "title": LoupeNode(
                    ref: "title",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    text: "Settings",
                    frame: LoupeRect(x: 290, y: 50, width: 80, height: 28),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
                "item": LoupeNode(
                    ref: "item",
                    parentRef: "root",
                    kind: .barButtonItem,
                    typeName: "ConflictingUserClassName",
                    role: "button",
                    text: "Edit",
                    frame: LoupeRect(x: 320, y: 50, width: 44, height: 28),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "ConflictingUserClassName",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false
                    )
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "title" })
    }

    @Test func auditIgnoresScrollOverlapReservedByAdjustedContentInset() {
        let snapshot = scrollInsetOverlapSnapshot(id: "layout-scroll-inset-overlap", adjustedBottom: 84)

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "messages" })
    }

    @Test func auditReportsScrollOverlapWithoutReservedInset() {
        let snapshot = scrollInsetOverlapSnapshot(id: "layout-scroll-real-overlap", adjustedBottom: 0)

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(audit.issues.contains { $0.kind == .overlappingSiblings && $0.ref == "messages" })
    }

    @Test func auditIgnoresDisabledControlContrast() {
        let white = LoupeColor(red: 1, green: 1, blue: 1, alpha: 1)
        let disabledGray = LoupeColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
        let snapshot = LoupeSnapshot(
            id: "layout-disabled-control-contrast",
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
                    style: LoupeStyle(backgroundColor: white),
                    children: ["send"]
                ),
                "send": LoupeNode(
                    ref: "send",
                    parentRef: "root",
                    kind: .view,
                    typeName: "DisabledSendControl",
                    role: "button",
                    text: "Send",
                    frame: LoupeRect(x: 320, y: 760, width: 52, height: 36),
                    isVisible: true,
                    isEnabled: false,
                    isInteractive: true,
                    style: LoupeStyle(backgroundColor: white, textColor: disabledGray),
                    uiKit: LoupeUIKitProperties(
                        className: "DisabledSendControl",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false,
                        control: LoupeUIControlProperties(controlState: "normal,disabled"),
                        button: LoupeUIButtonProperties()
                    ),
                    children: ["send-label"]
                ),
                "send-label": LoupeNode(
                    ref: "send-label",
                    parentRef: "send",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Send",
                    frame: LoupeRect(x: 327, y: 769, width: 38, height: 18),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(textColor: disabledGray)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "send" })
        #expect(!audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "send-label" })
    }

    @Test func auditIgnoresEmptyTextInputPlaceholderContrast() {
        let white = LoupeColor(red: 1, green: 1, blue: 1, alpha: 1)
        let placeholderGray = LoupeColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1)
        let snapshot = LoupeSnapshot(
            id: "layout-placeholder-contrast",
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
                    style: LoupeStyle(backgroundColor: white),
                    children: ["input", "body"]
                ),
                "input": LoupeNode(
                    ref: "input",
                    parentRef: "root",
                    kind: .view,
                    typeName: "CustomInputView",
                    text: "",
                    renderedText: "",
                    semanticText: "Aa",
                    frame: LoupeRect(x: 20, y: 760, width: 260, height: 38),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    style: LoupeStyle(backgroundColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 0)),
                    uiKit: LoupeUIKitProperties(
                        className: "CustomInputView",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: false,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false,
                        textView: LoupeUITextViewProperties()
                    ),
                    children: ["placeholder"]
                ),
                "placeholder": LoupeNode(
                    ref: "placeholder",
                    parentRef: "input",
                    kind: .view,
                    typeName: "CustomPlaceholderLabel",
                    role: "staticText",
                    text: "Aa",
                    frame: LoupeRect(x: 24, y: 768, width: 20, height: 20),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(textColor: placeholderGray)
                ),
                "body": LoupeNode(
                    ref: "body",
                    parentRef: "root",
                    kind: .view,
                    typeName: "UILabel",
                    role: "staticText",
                    text: "Body",
                    frame: LoupeRect(x: 20, y: 120, width: 80, height: 24),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    style: LoupeStyle(textColor: placeholderGray)
                ),
            ]
        )

        let audit = LoupeLayoutAuditor.audit(snapshot)

        #expect(!audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "placeholder" })
        #expect(audit.issues.contains { $0.kind == .lowTextContrast && $0.ref == "body" })
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

    private func scrollInsetOverlapSnapshot(id: String, adjustedBottom: Double) -> LoupeSnapshot {
        LoupeSnapshot(
            id: id,
            capturedAt: Date(timeIntervalSince1970: 0),
            screen: LoupeScreen(size: LoupeSize(width: 400, height: 800), scale: 3),
            rootRefs: ["root"],
            nodes: [
                "root": LoupeNode(
                    ref: "root",
                    parentRef: nil,
                    kind: .view,
                    typeName: "UIView",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false,
                    children: ["messages", "input"]
                ),
                "messages": LoupeNode(
                    ref: "messages",
                    parentRef: "root",
                    kind: .view,
                    typeName: "CustomMessagesList",
                    role: "collectionView",
                    frame: LoupeRect(x: 0, y: 0, width: 400, height: 800),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: true,
                    uiKit: LoupeUIKitProperties(
                        className: "CustomMessagesList",
                        tag: 0,
                        alpha: 1,
                        isHidden: false,
                        isOpaque: true,
                        clipsToBounds: false,
                        userInteractionEnabled: true,
                        isFirstResponder: false,
                        scrollView: LoupeUIScrollViewProperties(
                            contentOffset: LoupePoint(x: 0, y: 400),
                            contentSize: LoupeSize(width: 400, height: 1200),
                            adjustedContentInset: LoupeInsets(top: 0, left: 0, bottom: adjustedBottom, right: 0),
                            isScrollEnabled: true,
                            alwaysBounceVertical: true,
                            alwaysBounceHorizontal: false
                        )
                    )
                ),
                "input": LoupeNode(
                    ref: "input",
                    parentRef: "root",
                    kind: .view,
                    typeName: "CustomInputContainer",
                    semanticText: "Aa Send",
                    frame: LoupeRect(x: 0, y: 716, width: 400, height: 84),
                    isVisible: true,
                    isEnabled: true,
                    isInteractive: false
                ),
            ]
        )
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
                isFirstResponder: false,
                control: LoupeUIControlProperties(),
                button: LoupeUIButtonProperties()
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
                isFirstResponder: false,
                imageView: LoupeUIImageViewProperties()
            )
        )
    }

    private func swipeActionWrapper(ref: String, parentRef: String, text: String, x: Double) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: parentRef,
            kind: .view,
            typeName: "SwipeActionButtonWrapperView",
            text: text,
            frame: LoupeRect(x: x, y: 204, width: 804, height: 97),
            isVisible: true,
            isEnabled: true,
            isInteractive: false
        )
    }

    private func privateUIKitControl(
        ref: String,
        typeName: String,
        frame: LoupeRect,
        parentRef: String = "root",
        role: String? = "button",
        isInteractive: Bool = true
    ) -> LoupeNode {
        LoupeNode(
            ref: ref,
            parentRef: parentRef,
            kind: .view,
            typeName: typeName,
            role: role,
            frame: frame,
            isVisible: true,
            isEnabled: true,
            isInteractive: isInteractive,
            runtime: LoupeNodeRuntimeProperties(frameworkBundleIdentifier: "com.apple.UIKitCore"),
            uiKit: LoupeUIKitProperties(
                className: typeName,
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: isInteractive,
                isFirstResponder: false
            )
        )
    }
}
