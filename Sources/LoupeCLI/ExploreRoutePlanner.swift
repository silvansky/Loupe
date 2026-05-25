import Foundation
import LoupeCore

enum ExploreRoutePlanner {
    static func candidates(
        in snapshot: LoupeSnapshot,
        visitedKeys: Set<String> = [],
        limit: Int = Int.max
    ) -> [ExploreRouteCandidate] {
        snapshot.nodes.values
            .compactMap { candidate(for: $0, screen: snapshot.screen.size) }
            .filter { !visitedKeys.contains($0.key) }
            .sorted(by: routeOrder)
            .reduce(into: [ExploreRouteCandidate]()) { result, candidate in
                guard result.count < limit else { return }
                guard !result.contains(where: { overlapsRoute($0.frame, candidate.frame) && $0.reason == candidate.reason }) else {
                    return
                }
                result.append(candidate)
            }
    }

    private static func candidate(for node: LoupeNode, screen: LoupeSize) -> ExploreRouteCandidate? {
        guard node.isVisible, node.isEnabled, let frame = node.frame, !frame.isEmpty else {
            return nil
        }
        guard frame.width >= 20, frame.height >= 20 else {
            return nil
        }
        guard frame.intersects(LoupeRect(x: 0, y: 0, width: screen.width, height: screen.height)) else {
            return nil
        }
        guard let center = center(of: frame), center.x >= 0, center.y >= 0, center.x <= screen.width, center.y <= screen.height else {
            return nil
        }
        guard !isExcluded(node) else {
            return nil
        }

        let role = node.role?.lowercased()
        let text = LoupeObservationCompactor.displayText(for: node)
        let reason: String
        if role == "cell" {
            reason = "cell"
        } else if role == "button" {
            reason = "button"
        } else if role == "link" {
            reason = "link"
        } else if role == "tab" {
            reason = "tab"
        } else if node.isInteractive {
            reason = "interactive"
        } else {
            return nil
        }

        return ExploreRouteCandidate(
            ref: node.ref,
            typeName: node.typeName,
            role: node.role,
            testID: node.testID,
            text: text,
            frame: frame,
            center: center,
            reason: reason,
            key: routeKey(node: node, frame: frame, text: text)
        )
    }

    private static func isExcluded(_ node: LoupeNode) -> Bool {
        if ["application", "scene", "window", "scrollbar"].contains(node.role?.lowercased() ?? "") {
            return true
        }
        let identity = [
            node.testID,
            node.label,
            node.text,
            node.renderedText,
            node.semanticText,
            LoupeObservationCompactor.displayText(for: node),
        ]
        .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        if identity.contains("back") || identity.contains("뒤로") || identity.contains("backbutton") {
            return true
        }
        if identity.contains(where: { $0.contains("chevron.backward") }) {
            return true
        }
        return false
    }

    private static func routeKey(node: LoupeNode, frame: LoupeRect, text: String?) -> String {
        if let testID = node.testID, !testID.isEmpty {
            return "testID:\(testID)"
        }
        if let text, !text.isEmpty {
            return "text:\(node.role ?? ""):\(text)"
        }
        return [
            "frame",
            node.role ?? "",
            node.typeName,
            String(Int(frame.x.rounded())),
            String(Int(frame.y.rounded())),
            String(Int(frame.width.rounded())),
            String(Int(frame.height.rounded())),
        ].joined(separator: ":")
    }

    private static func routeOrder(_ lhs: ExploreRouteCandidate, _ rhs: ExploreRouteCandidate) -> Bool {
        let lhsRank = rank(lhs.reason)
        let rhsRank = rank(rhs.reason)
        if lhsRank != rhsRank {
            return lhsRank < rhsRank
        }
        if abs(lhs.frame.y - rhs.frame.y) > 1 {
            return lhs.frame.y < rhs.frame.y
        }
        if abs(lhs.frame.x - rhs.frame.x) > 1 {
            return lhs.frame.x < rhs.frame.x
        }
        return lhs.ref < rhs.ref
    }

    private static func rank(_ reason: String) -> Int {
        switch reason {
        case "cell": return 0
        case "button": return 1
        case "link": return 2
        case "tab": return 3
        default: return 4
        }
    }

    private static func overlapsRoute(_ lhs: LoupeRect, _ rhs: LoupeRect) -> Bool {
        let area = min(lhs.width * lhs.height, rhs.width * rhs.height)
        guard area > 0 else { return false }
        return lhs.intersectionArea(with: rhs) / area > 0.9
    }

    private static func center(of frame: LoupeRect) -> LoupePoint? {
        guard !frame.isEmpty else { return nil }
        return LoupePoint(x: frame.x + frame.width / 2, y: frame.y + frame.height / 2)
    }
}
