import Foundation

public enum LoupeSelector: Equatable {
    case testID(String)
    case text(String, exact: Bool = true)
    case role(String)
    case roleAndText(role: String, text: String, exact: Bool = true)
    case ref(String)
}

public struct LoupeQueryOptions: Equatable {
    public var includeHidden: Bool
    public var includeDisabled: Bool
    public var maxResults: Int

    public init(
        includeHidden: Bool = false,
        includeDisabled: Bool = true,
        maxResults: Int = 50
    ) {
        self.includeHidden = includeHidden
        self.includeDisabled = includeDisabled
        self.maxResults = maxResults
    }
}

public struct LoupeQueryResult: Codable, Equatable {
    public var ref: String
    public var role: String?
    public var text: String?
    public var testID: String?
    public var frame: LoupeRect?
    public var isVisible: Bool
    public var isEnabled: Bool
    public var isInteractive: Bool

    public init(node: LoupeNode) {
        ref = node.ref
        role = node.role
        text = LoupeObservationCompactor.displayText(for: node)
        testID = node.testID
        frame = node.frame
        isVisible = node.isVisible
        isEnabled = node.isEnabled
        isInteractive = node.isInteractive
    }
}

public enum LoupeSnapshotQuery {
    public static func find(
        _ selector: LoupeSelector,
        in snapshot: LoupeSnapshot,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> [LoupeQueryResult] {
        let screenRect = LoupeRect(
            x: 0,
            y: 0,
            width: snapshot.screen.size.width,
            height: snapshot.screen.size.height
        )
        return snapshot.nodes.values
            .filter { matchesVisibilityAndState($0, options: options) }
            .filter { matches(selector, node: $0) }
            .filter { !suppressesAggregateTextMatch($0, selector: selector, screenRect: screenRect, snapshot: snapshot) }
            .sorted { resultOrder($0, $1, selector: selector) }
            .prefix(options.maxResults)
            .map(LoupeQueryResult.init)
    }

    public static func first(
        _ selector: LoupeSelector,
        in snapshot: LoupeSnapshot,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> LoupeQueryResult? {
        find(selector, in: snapshot, options: options).first
    }

    private static func matchesVisibilityAndState(
        _ node: LoupeNode,
        options: LoupeQueryOptions
    ) -> Bool {
        if !options.includeHidden, !node.isVisible {
            return false
        }

        if !options.includeDisabled, !node.isEnabled {
            return false
        }

        return true
    }

    private static func matches(_ selector: LoupeSelector, node: LoupeNode) -> Bool {
        switch selector {
        case let .testID(testID):
            return node.testID == testID || stringMetadata("id", from: node.custom) == testID
        case let .text(text, exact):
            return matchesText(text, exact: exact, node: node)
        case let .role(role):
            return node.role == role
        case let .roleAndText(role, text, exact):
            return node.role == role && matchesText(text, exact: exact, node: node)
        case let .ref(ref):
            return node.ref == ref
        }
    }

    private static func matchesText(
        _ text: String,
        exact: Bool,
        node: LoupeNode
    ) -> Bool {
        guard let displayText = LoupeObservationCompactor.displayText(for: node) else {
            return false
        }

        if exact {
            return displayText == text
        }

        return displayText.localizedCaseInsensitiveContains(text)
    }

    private static func resultOrder(_ lhs: LoupeNode, _ rhs: LoupeNode, selector: LoupeSelector) -> Bool {
        let lhsTextRank = textSpecificityRank(lhs, selector: selector)
        let rhsTextRank = textSpecificityRank(rhs, selector: selector)
        if lhsTextRank != rhsTextRank {
            return lhsTextRank < rhsTextRank
        }

        if (lhs.role != nil) != (rhs.role != nil) {
            return lhs.role != nil
        }

        if lhs.isInteractive != rhs.isInteractive {
            return lhs.isInteractive && !rhs.isInteractive
        }

        guard let lhsFrame = lhs.frame else { return false }
        guard let rhsFrame = rhs.frame else { return true }

        if abs(lhsFrame.y - rhsFrame.y) > 1 {
            return lhsFrame.y < rhsFrame.y
        }

        return lhsFrame.x < rhsFrame.x
    }

    private static func textSpecificityRank(_ node: LoupeNode, selector: LoupeSelector) -> Int {
        guard let query = textQuery(from: selector),
              let displayText = LoupeObservationCompactor.displayText(for: node) else {
            return 0
        }
        if displayText.compare(query.text, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
            return 0
        }
        return displayText.count <= query.text.count + 12 ? 1 : 2
    }

    private static func textQuery(from selector: LoupeSelector) -> (text: String, exact: Bool)? {
        switch selector {
        case let .text(text, exact):
            return (text, exact)
        case let .roleAndText(_, text, exact):
            return (text, exact)
        default:
            return nil
        }
    }

    private static func suppressesAggregateTextMatch(
        _ node: LoupeNode,
        selector: LoupeSelector,
        screenRect: LoupeRect,
        snapshot: LoupeSnapshot
    ) -> Bool {
        guard case .text = selector else {
            return false
        }
        guard node.testID == nil else {
            return false
        }
        if suppressesSystemChromeSemanticDuplicateText(node, in: snapshot, screenRect: screenRect) {
            return true
        }
        if node.uiKit?.scrollView != nil {
            return true
        }
        switch node.role?.lowercased() {
        case "collectionview", "tableview", "scrollview", "window", "navigationbar":
            return true
        default:
            break
        }
        guard node.role == nil, !node.children.isEmpty, let frame = node.frame else {
            return false
        }
        let screenArea = area(screenRect)
        guard screenArea > 0 else {
            return false
        }
        return area(frame) / screenArea >= 0.5
    }

    private static func suppressesSystemChromeSemanticDuplicateText(
        _ node: LoupeNode,
        in snapshot: LoupeSnapshot,
        screenRect: LoupeRect
    ) -> Bool {
        guard isRolelessAppleSystemChromeAggregate(node, in: snapshot),
              isSemanticOnlyDisplayText(node),
              let text = LoupeObservationCompactor.displayText(for: node) else {
            return false
        }
        return hasSpecificVisibleTextMatch(text, excluding: node.ref, in: snapshot, screenRect: screenRect)
    }

    private static func isRolelessAppleSystemChromeAggregate(_ node: LoupeNode, in snapshot: LoupeSnapshot) -> Bool {
        guard node.runtime?.frameworkBundleIdentifier?.hasPrefix("com.apple.") == true,
              node.testID == nil,
              node.role == nil,
              node.accessibility?.isElement != true else {
            return false
        }
        return isSystemChromeDescendant(node, in: snapshot)
    }

    private static func isSystemChromeDescendant(_ node: LoupeNode, in snapshot: LoupeSnapshot) -> Bool {
        if isSystemChromeRole(node.role) {
            return true
        }
        var currentRef = node.parentRef
        while let ref = currentRef, let current = snapshot.nodes[ref] {
            if isSystemChromeRole(current.role) {
                return true
            }
            currentRef = current.parentRef
        }
        return false
    }

    private static func isSystemChromeRole(_ role: String?) -> Bool {
        role == "navigationBar" || role == "tabBar" || role == "toolbar"
    }

    private static func isSemanticOnlyDisplayText(_ node: LoupeNode) -> Bool {
        nonEmpty(node.semanticText) != nil
            && nonEmpty(node.text) == nil
            && nonEmpty(node.renderedText) == nil
            && nonEmpty(node.label) == nil
            && nonEmpty(node.value) == nil
            && nonEmpty(node.placeholder) == nil
    }

    private static func hasSpecificVisibleTextMatch(
        _ text: String,
        excluding ref: String,
        in snapshot: LoupeSnapshot,
        screenRect: LoupeRect
    ) -> Bool {
        snapshot.nodes.values.contains { candidate in
            guard candidate.ref != ref,
                  candidate.isVisible,
                  let frame = candidate.frame,
                  frame.intersects(screenRect),
                  LoupeObservationCompactor.displayText(for: candidate) == text else {
                return false
            }
            return isSpecificTextNode(candidate)
        }
    }

    private static func isSpecificTextNode(_ node: LoupeNode) -> Bool {
        node.testID != nil
            || node.role != nil
            || node.accessibility?.isElement == true
            || !isSemanticOnlyDisplayText(node)
    }

    private static func nonEmpty(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private static func area(_ rect: LoupeRect) -> Double {
        max(0, rect.width) * max(0, rect.height)
    }

    private static func stringMetadata(
        _ key: String,
        from metadata: [String: LoupeMetadataValue]
    ) -> String? {
        guard case let .string(value) = metadata[key] else {
            return nil
        }
        return value
    }
}
