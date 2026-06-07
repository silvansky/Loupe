import Foundation

public enum LoupeSurfaceVisibility {
    public static func visibleNodeRefs(in snapshot: LoupeSnapshot, includesOffscreen: Bool = false) -> Set<String> {
        guard snapshot.screen.size.width > 0, snapshot.screen.size.height > 0 else {
            return Set(snapshot.nodes.values.compactMap { $0.isVisible ? $0.ref : nil })
        }

        let screenRect = LoupeRect(
            x: 0,
            y: 0,
            width: snapshot.screen.size.width,
            height: snapshot.screen.size.height
        )
        let orders = paintOrders(snapshot)
        let paintCandidates = snapshot.nodes.values
            .filter { node in
                guard node.isVisible, let frame = node.frame, frame.intersects(screenRect) else {
                    return false
                }
                return isPaintCandidate(node)
            }
            .sorted { lhs, rhs in
                let lhsOrder = orders[lhs.ref] ?? 0
                let rhsOrder = orders[rhs.ref] ?? 0
                if lhsOrder != rhsOrder {
                    return lhsOrder > rhsOrder
                }
                return lhs.ref > rhs.ref
            }

        return Set(snapshot.nodes.values.compactMap { node in
            guard isSurfaceVisible(
                node,
                in: snapshot,
                screenRect: screenRect,
                includesOffscreen: includesOffscreen,
                paintCandidates: paintCandidates
            ) else {
                return nil
            }
            return node.ref
        })
    }

    public static func isSurfaceVisible(_ node: LoupeNode, in snapshot: LoupeSnapshot) -> Bool {
        visibleNodeRefs(in: snapshot).contains(node.ref)
    }

    static func isSurfaceVisible(
        _ node: LoupeNode,
        in snapshot: LoupeSnapshot,
        visibleRefs: Set<String>?,
        includesOffscreen: Bool = false
    ) -> Bool {
        guard let visibleRefs else {
            return node.isVisible
        }
        return visibleRefs.contains(node.ref)
    }

    private static func isSurfaceVisible(
        _ node: LoupeNode,
        in snapshot: LoupeSnapshot,
        screenRect: LoupeRect,
        includesOffscreen: Bool,
        paintCandidates: [LoupeNode]
    ) -> Bool {
        if isActiveTextInput(node, on: screenRect) {
            return true
        }

        guard node.isVisible else {
            return false
        }

        guard let frame = node.frame else {
            return true
        }
        guard frame.intersects(screenRect) else {
            return includesOffscreen
        }

        let samples = samplePoints(in: frame, clippedTo: screenRect)
        guard !samples.isEmpty else {
            return false
        }

        return samples.contains { point in
            guard let top = paintCandidates.first(where: { candidate in
                candidate.frame?.contains(point) == true
            }) else {
                return true
            }
            return isRelated(node.ref, top.ref, in: snapshot)
        }
    }

    private static func isPaintCandidate(_ node: LoupeNode) -> Bool {
        guard node.kind == .view else {
            return false
        }
        if isSyntheticProbe(node) {
            return false
        }

        if hasOwnPaintedText(node) {
            return true
        }
        if node.testID != nil,
           let semanticText = node.semanticText?.trimmingCharacters(in: .whitespacesAndNewlines),
           !semanticText.isEmpty {
            return true
        }
        if node.isInteractive, node.accessibility?.isElement == true {
            return true
        }
        if node.uiKit?.imageView != nil {
            return true
        }
        if let color = node.style?.backgroundColor, color.alpha >= 0.95 {
            return true
        }
        return false
    }

    private static func hasOwnPaintedText(_ node: LoupeNode) -> Bool {
        if [node.text, node.renderedText, node.label, node.value, node.placeholder].contains(where: {
            $0?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        }) {
            return true
        }

        guard let semanticText = node.semanticText?.trimmingCharacters(in: .whitespacesAndNewlines),
              !semanticText.isEmpty
        else {
            return false
        }

        return node.children.isEmpty
            || node.accessibility?.isElement == true
            || node.isInteractive
    }

    private static func isSyntheticProbe(_ node: LoupeNode) -> Bool {
        node.custom["loupe.probe"] == .bool(true)
    }

    private static func isActiveTextInput(_ node: LoupeNode, on screenRect: LoupeRect) -> Bool {
        guard node.kind == .view,
              node.role == "textField" || node.uiKit?.textField != nil || node.uiKit?.textView != nil,
              node.uiKit?.isFirstResponder == true,
              node.uiKit?.isHidden == false,
              (node.uiKit?.alpha ?? 1) > 0.01,
              let frame = node.frame,
              frame.intersects(screenRect)
        else {
            return false
        }
        return true
    }

    private static func samplePoints(in frame: LoupeRect, clippedTo screenRect: LoupeRect) -> [LoupePoint] {
        let minX = max(frame.x, screenRect.x)
        let minY = max(frame.y, screenRect.y)
        let maxX = min(frame.maxX, screenRect.maxX)
        let maxY = min(frame.maxY, screenRect.maxY)
        guard minX < maxX, minY < maxY else {
            return []
        }

        let width = maxX - minX
        let height = maxY - minY
        let insetX = min(4, width * 0.2)
        let insetY = min(4, height * 0.2)
        let center = LoupePoint(x: minX + width / 2, y: minY + height / 2)

        guard width > 8, height > 8 else {
            return [center]
        }

        return [
            center,
            LoupePoint(x: minX + insetX, y: minY + insetY),
            LoupePoint(x: maxX - insetX, y: minY + insetY),
            LoupePoint(x: minX + insetX, y: maxY - insetY),
            LoupePoint(x: maxX - insetX, y: maxY - insetY),
        ]
    }

    private static func isRelated(_ lhsRef: String, _ rhsRef: String, in snapshot: LoupeSnapshot) -> Bool {
        lhsRef == rhsRef
            || isAncestor(lhsRef, of: rhsRef, in: snapshot)
            || isAncestor(rhsRef, of: lhsRef, in: snapshot)
    }

    private static func isAncestor(_ ancestorRef: String, of descendantRef: String, in snapshot: LoupeSnapshot) -> Bool {
        var ref = snapshot.nodes[descendantRef]?.parentRef
        while let currentRef = ref {
            if currentRef == ancestorRef {
                return true
            }
            ref = snapshot.nodes[currentRef]?.parentRef
        }
        return false
    }

    private static func paintOrders(_ snapshot: LoupeSnapshot) -> [String: Int] {
        var order = 0
        var orders: [String: Int] = [:]
        func visit(_ ref: String) {
            guard let node = snapshot.nodes[ref] else { return }
            orders[ref] = order
            order += 1
            for child in node.children {
                visit(child)
            }
        }
        for root in snapshot.rootRefs {
            visit(root)
        }
        return orders
    }
}
