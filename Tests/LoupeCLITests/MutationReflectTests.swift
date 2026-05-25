@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct MutationReflectTests {
    @Test func reflectUsesCustomTargetTypeAsSourceTerm() throws {
        let sourceRoot = FileManager.default.temporaryDirectory
            .appendingPathComponent("loupe-reflect-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: sourceRoot)
        }

        let source = sourceRoot.appendingPathComponent("MailCell.swift")
        try """
        import UIKit

        class MailCell: UITableViewCell {
            func configure() {}
        }
        """.write(to: source, atomically: true, encoding: .utf8)

        let target = LoupeNode(
            ref: "n108",
            parentRef: "n9",
            kind: .view,
            typeName: "MailCell",
            role: "cell",
            frame: LoupeRect(x: 0, y: 204, width: 402, height: 97),
            isVisible: true,
            isEnabled: true,
            isInteractive: true
        )
        let response = LoupeMutationResponse(
            property: "backgroundColor",
            selector: LoupeMutationSelector(kind: .ref, value: "n108"),
            value: .color(LoupeColor(red: 0.99, green: 0.89, blue: 0.89, alpha: 1)),
            target: LoupeQueryResult(node: target),
            before: target,
            after: target,
            hierarchy: LoupeMutationHierarchyContext(target: LoupeMutationNodeSummary(ref: "n108", typeName: "MailCell")),
            changed: true,
            snapshotID: "snapshot"
        )

        let reflection = LoupeCLI.mutationReflection(response, sourceRoot: sourceRoot)

        #expect(reflection.sourceCandidates.contains { candidate in
            candidate.path.hasSuffix("MailCell.swift")
                && candidate.text == "class MailCell: UITableViewCell {"
        })
    }
}
