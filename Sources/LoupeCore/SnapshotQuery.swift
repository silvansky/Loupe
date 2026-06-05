import Foundation

public enum LoupeSelector: Equatable {
    case testID(String)
    case text(String, exact: Bool = true)
    case role(String)
    case roleAndText(role: String, text: String, exact: Bool = true)
    case ref(String)
}

public enum LoupeQueryVisibilityMode: Equatable {
    case surface
    case occlusion
    case raw
}

public struct LoupeQueryOptions: Equatable {
    public var includeHidden: Bool
    public var includeDisabled: Bool
    public var maxResults: Int
    public var visibilityMode: LoupeQueryVisibilityMode

    public init(
        includeHidden: Bool = false,
        includeDisabled: Bool = true,
        maxResults: Int = 50,
        visibilityMode: LoupeQueryVisibilityMode = .surface
    ) {
        self.includeHidden = includeHidden
        self.includeDisabled = includeDisabled
        self.maxResults = maxResults
        self.visibilityMode = visibilityMode
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

    public init(node: LoupeNode, isVisible: Bool? = nil) {
        ref = node.ref
        role = node.role
        text = LoupeObservationCompactor.displayText(for: node)
        testID = node.testID
        frame = node.frame
        self.isVisible = isVisible ?? node.isVisible
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
        let surfaceVisibleRefs = shouldUseSurfaceVisibility(options)
            ? LoupeSurfaceVisibility.visibleNodeRefs(
                in: snapshot,
                includesOffscreen: options.visibilityMode == .occlusion
            )
            : nil
        return snapshot.nodes.values
            .filter { matchesVisibilityAndState($0, options: options, surfaceVisibleRefs: surfaceVisibleRefs, snapshot: snapshot) }
            .filter { matches(selector, node: $0) }
            .sorted(by: resultOrder)
            .prefix(options.maxResults)
            .map { node in
                LoupeQueryResult(
                    node: node,
                    isVisible: surfaceVisibleRefs.map { $0.contains(node.ref) }
                )
            }
    }

    public static func first(
        _ selector: LoupeSelector,
        in snapshot: LoupeSnapshot,
        options: LoupeQueryOptions = LoupeQueryOptions()
    ) -> LoupeQueryResult? {
        find(selector, in: snapshot, options: options).first
    }

    package static func preferPlatformBackedMatches(
        _ matches: [LoupeQueryResult],
        in snapshot: LoupeSnapshot
    ) -> [LoupeQueryResult] {
        let grouped = Dictionary(grouping: matches, by: querySemanticKey)
        let keysWithPlatformBackedAlternative = Set(grouped.compactMap { key, group -> String? in
            let platformBacked = group.filter { !isSyntheticRegisteredProbeSource($0.ref, in: snapshot) }
            let syntheticCount = group.count - platformBacked.count
            if !platformBacked.isEmpty, syntheticCount > 0 {
                return key
            }
            return nil
        })

        return matches.filter { match in
            let key = querySemanticKey(match)
            guard keysWithPlatformBackedAlternative.contains(key) else {
                return true
            }
            return !isSyntheticRegisteredProbeSource(match.ref, in: snapshot)
        }
    }

    package static func isSyntheticRegisteredProbeSource(_ sourceRef: String, in snapshot: LoupeSnapshot) -> Bool {
        guard let node = snapshot.nodes[sourceRef] else {
            return false
        }
        return isSyntheticRegisteredProbe(node)
    }

    private static func matchesVisibilityAndState(
        _ node: LoupeNode,
        options: LoupeQueryOptions,
        surfaceVisibleRefs: Set<String>?,
        snapshot: LoupeSnapshot
    ) -> Bool {
        if !options.includeHidden, !isVisible(node, in: snapshot, options: options, surfaceVisibleRefs: surfaceVisibleRefs) {
            return false
        }

        if !options.includeDisabled, !node.isEnabled {
            return false
        }

        return true
    }

    private static func shouldUseSurfaceVisibility(_ options: LoupeQueryOptions) -> Bool {
        !options.includeHidden && options.visibilityMode != .raw
    }

    private static func isVisible(
        _ node: LoupeNode,
        in snapshot: LoupeSnapshot,
        options: LoupeQueryOptions,
        surfaceVisibleRefs: Set<String>?
    ) -> Bool {
        switch options.visibilityMode {
        case .surface:
            return LoupeSurfaceVisibility.isSurfaceVisible(
                node,
                in: snapshot,
                visibleRefs: surfaceVisibleRefs
            )
        case .occlusion:
            return LoupeSurfaceVisibility.isSurfaceVisible(
                node,
                in: snapshot,
                visibleRefs: surfaceVisibleRefs,
                includesOffscreen: true
            )
        case .raw:
            return node.isVisible
        }
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

    private static func resultOrder(_ lhs: LoupeNode, _ rhs: LoupeNode) -> Bool {
        if lhs.isInteractive != rhs.isInteractive {
            return lhs.isInteractive && !rhs.isInteractive
        }

        if lhs.isVisible != rhs.isVisible {
            return lhs.isVisible && !rhs.isVisible
        }

        let lhsSynthetic = isSyntheticRegisteredProbe(lhs)
        let rhsSynthetic = isSyntheticRegisteredProbe(rhs)
        if lhsSynthetic != rhsSynthetic {
            return !lhsSynthetic && rhsSynthetic
        }

        guard let lhsFrame = lhs.frame else { return false }
        guard let rhsFrame = rhs.frame else { return true }

        if abs(lhsFrame.y - rhsFrame.y) > 1 {
            return lhsFrame.y < rhsFrame.y
        }

        return lhsFrame.x < rhsFrame.x
    }

    package static func isSyntheticRegisteredProbe(_ node: LoupeNode) -> Bool {
        node.typeName == "LoupeRegisteredProbe"
            || node.custom["synthetic"] == .bool(true)
            || node.custom["observationBackend"] == .string("registered-probes")
    }

    private static func querySemanticKey(_ match: LoupeQueryResult) -> String {
        [
            match.role ?? "",
            match.testID ?? "",
            match.text ?? "",
        ].joined(separator: "|")
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
