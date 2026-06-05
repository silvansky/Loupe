@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct MutationReflectTests {
    @Test func reflectFallsBackToHierarchySourceHintsWhenTestIDIsMissing() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("SwiggyClone", isDirectory: true)
        let views = sourceRoot.appendingPathComponent("Scenes/Views/Food/Views", isDirectory: true)
        try FileManager.default.createDirectory(at: views, withIntermediateDirectories: true)
        let cellSource = views.appendingPathComponent("RestaurantsListCVCell.swift")
        try """
        import UIKit

        final class RestaurantsListCVCell: UICollectionViewCell {
            let restaurantNameLabel: UILabel = {
                let label = UILabel()
                label.textColor = .black
                return label
            }()
        }
        """.write(to: cellSource, atomically: true, encoding: .utf8)

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseWithoutTestID()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )
        let candidateTexts = reflection.sourceCandidates.map(\.text)

        #expect(reflection.testID == nil)
        #expect(reflection.sourceCandidates.contains { $0.path.hasSuffix("RestaurantsListCVCell.swift") })
        #expect(candidateTexts.contains { $0.contains("textColor = .black") })
        #expect(candidateTexts.contains { $0.contains("restaurantNameLabel") })
    }

    @Test func reflectUsesAncestorTypeWhenImmediateParentIsGenericContentView() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("Eureka", isDirectory: true)
        let rows = sourceRoot.appendingPathComponent("Source/Rows", isDirectory: true)
        let core = sourceRoot.appendingPathComponent("Source/Core", isDirectory: true)
        try FileManager.default.createDirectory(at: rows, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: core, withIntermediateDirectories: true)
        try """
        import UIKit

        open class SwitchCell: Cell<Bool>, CellType {
            open var switchControl = UISwitch()
        }

        public final class SwitchRow: Row<SwitchCell>, RowType {}
        """.write(
            to: rows.appendingPathComponent("SwitchRow.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import UIKit

        open class Cell<Value>: UITableViewCell {
            func update() {
                textLabel?.textColor = .label
            }
        }
        """.write(
            to: core.appendingPathComponent("Cell.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForGenericContentViewLabelWithCellAncestor()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.first?.path.hasSuffix("SwitchRow.swift") == true)
        #expect(reflection.sourceCandidates.contains { $0.text.contains("SwitchCell") })
        #expect(!reflection.sourceCandidates.contains { $0.path.hasSuffix("Cell.swift") })
    }

    @Test func reflectAcceptsSetManySummaryWithResponses() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("MessageKit", isDirectory: true)
        let cells = sourceRoot.appendingPathComponent("Sources/Views/Cells", isDirectory: true)
        try FileManager.default.createDirectory(at: cells, withIntermediateDirectories: true)
        try """
        import UIKit

        open class TextMessageCell: UICollectionViewCell {
            open var messageLabel = MessageLabel()

            open func configure() {
                let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
                messageLabel.textColor = textColor
            }
        }
        """.write(
            to: cells.appendingPathComponent("TextMessageCell.swift"),
            atomically: true,
            encoding: .utf8
        )

        let response = mutationResponseForMessageKitMessageLabel()
        let responsesURL = root.appendingPathComponent("responses.json")
        let summaryURL = root.appendingPathComponent("summary.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        try JSONEncoder().encode([response]).write(to: responsesURL)
        let summary = BatchMutationResult(
            host: "http://127.0.0.1:28827",
            elapsedMs: 120,
            selector: "typeName:MessageLabel",
            property: "textColor",
            valueSequence: "color",
            visibleOnly: true,
            yRange: nil,
            matchedTargets: 1,
            mutationRequests: 1,
            changedMutations: 1,
            verifiedTargets: 1,
            accuracy: 1,
            prevSnapshot: root.appendingPathComponent("prev-snapshot.json").path,
            nextSnapshot: root.appendingPathComponent("next-snapshot.json").path,
            diff: root.appendingPathComponent("diff.json").path,
            targets: root.appendingPathComponent("targets.json").path,
            responses: responsesURL.path,
            traceDirectory: root.path
        )
        try JSONEncoder().encode(summary).write(to: summaryURL)

        try LoupeCLI.reflect([
            summaryURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflections = try JSONDecoder().decode(
            [LoupeMutationReflection].self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflections.count == 1)
        #expect(reflections[0].targetType == "MessageLabel")
        #expect(reflections[0].sourceCandidates.first?.path.hasSuffix("TextMessageCell.swift") == true)
        #expect(reflections[0].sourceCandidates.contains { $0.text.contains("messageLabel.textColor") })
    }

    @Test func reflectPrioritizesExactHierarchyTypeOverSubstringPropertyMatches() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("UpcomingMovies", isDirectory: true)
        let sharedViews = sourceRoot.appendingPathComponent("ViewComponents/CustomViews", isDirectory: true)
        let accountViews = sourceRoot.appendingPathComponent("Scenes/Account/CustomListDetail/HeaderView", isDirectory: true)
        try FileManager.default.createDirectory(at: sharedViews, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: accountViews, withIntermediateDirectories: true)
        try """
        import UIKit

        class HeaderView: UIView {
            private lazy var headerTitleLabel: UILabel = {
                let label = UILabel()
                label.textAlignment = .left
                return label
            }()
        }
        """.write(
            to: sharedViews.appendingPathComponent("HeaderView.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import UIKit

        final class CustomListDetailHeaderView: UIView {
            private func setupLabels() {
                nameLabel.textColor = ColorPalette.darkBlueColor
            }
        }
        """.write(
            to: accountViews.appendingPathComponent("CustomListDetailHeaderView.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForHeaderViewLabel()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.first?.path.hasSuffix("HeaderView.swift") == true)
        #expect(reflection.sourceCandidates.first?.text.contains("class HeaderView") == true)
    }

    @Test func reflectAvoidsAlphaSubstringAndRanksSwiftUINavigationTitleLiteral() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("Harbour", isDirectory: true)
        let views = sourceRoot.appendingPathComponent("Harbour/UI/Views", isDirectory: true)
        let setup = views.appendingPathComponent("SetupView", isDirectory: true)
        try FileManager.default.createDirectory(at: views, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: setup, withIntermediateDirectories: true)
        try """
        import SwiftUI

        struct TextEditorView: View {
            var body: some View {
                TextEditor(text: .constant(""))
                    .keyboardType(.alphabet)
            }
        }
        """.write(
            to: views.appendingPathComponent("TextEditorView.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import SwiftUI

        struct SetupView: View {
            var body: some View {
                Form {
                    Text("SetupView.URL")
                }
                .navigationTitle("SetupView.Title")
            }
        }
        """.write(
            to: setup.appendingPathComponent("SetupView.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForSwiftUINavigationTitle()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.first?.path.hasSuffix("SetupView.swift") == true)
        #expect(reflection.sourceCandidates.first?.text.contains(".navigationTitle(\"SetupView.Title\")") == true)
        #expect(!reflection.sourceCandidates.contains { $0.text.contains(".keyboardType(.alphabet)") })
    }

    @Test func reflectExtractsSwiftUIContentTypeFromHostingGeneric() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("Loop", isDirectory: true)
        let settings = sourceRoot.appendingPathComponent("Loop/Settings Window", isDirectory: true)
        try FileManager.default.createDirectory(at: settings, withIntermediateDirectories: true)
        try """
        import SwiftUI

        struct SettingsContentView: View {
            var body: some View {
                Text("Loop settings")
            }
        }
        """.write(
            to: settings.appendingPathComponent("SettingsContentView.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import SwiftUI

        struct OtherView: View {
            var body: some View {
                TextField("Other", text: .constant(""))
                    .keyboardType(.alphabet)
            }
        }
        """.write(
            to: settings.appendingPathComponent("OtherView.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForSwiftUIHostingView()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.first?.path.hasSuffix("SettingsContentView.swift") == true)
        #expect(reflection.sourceCandidates.first?.text.contains("struct SettingsContentView") == true)
        #expect(!reflection.sourceCandidates.contains { $0.text.contains(".keyboardType(.alphabet)") })
    }

    @Test func reflectIgnoresSwiftUIInfrastructureOnlyGenericTerms() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("Dime", isDirectory: true)
        let utilities = sourceRoot.appendingPathComponent("dime/Utilities", isDirectory: true)
        try FileManager.default.createDirectory(at: utilities, withIntermediateDirectories: true)
        try """
        import SwiftUI

        private struct KeyboardAwareModifier: ViewModifier {
            func body(content: Content) -> some View {
                ModifiedContent(content: content, modifier: self)
            }
        }
        """.write(
            to: utilities.appendingPathComponent("KeyboardHeightHelper.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import SwiftUI

        extension Color {
            func blend(over color: Color, withAlpha alpha: CGFloat) -> Color {
                Color(UIColor(red: 0, green: 0, blue: 0, alpha: 1))
            }
        }
        """.write(
            to: utilities.appendingPathComponent("Color.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForSwiftUIListCellHostingView()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.isEmpty)
    }

    @Test func reflectRanksAppKitIdentifierAssignmentBeforeSelectorReferences() throws {
        let root = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: root) }

        let sourceRoot = root.appendingPathComponent("CotEditor", isDirectory: true)
        let application = sourceRoot.appendingPathComponent("CotEditor/Sources/Application", isDirectory: true)
        let contentView = sourceRoot.appendingPathComponent("CotEditor/Sources/Document Window/Content View", isDirectory: true)
        let textView = sourceRoot.appendingPathComponent("CotEditor/Sources/Document Window/Text View", isDirectory: true)
        try FileManager.default.createDirectory(at: application, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: contentView, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: textView, withIntermediateDirectories: true)
        try """
        import AppKit

        final class AppDelegate: NSObject {
            func validateMenuItem(_ item: NSMenuItem) {
                item.action = #selector(EditorTextView.normalizeUnicode(_:))
            }
        }
        """.write(
            to: application.appendingPathComponent("AppDelegate.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import AppKit

        final class EditorTextViewController: NSViewController {
            private(set) var textView: EditorTextView!

            override func loadView() {
                let textView = EditorTextView(frame: .zero)
                self.textView = textView
            }
        }
        """.write(
            to: contentView.appendingPathComponent("EditorTextViewController.swift"),
            atomically: true,
            encoding: .utf8
        )
        try """
        import AppKit

        final class EditorTextView: NSTextView {
            override init(frame frameRect: NSRect, textContainer container: NSTextContainer?) {
                super.init(frame: frameRect, textContainer: container)
                self.identifier = NSUserInterfaceItemIdentifier("EditorTextView")
            }
        }
        """.write(
            to: textView.appendingPathComponent("EditorTextView.swift"),
            atomically: true,
            encoding: .utf8
        )

        let mutationURL = root.appendingPathComponent("mutation.json")
        let outputURL = root.appendingPathComponent("reflection.json")
        let response = mutationResponseForAppKitEditorTextView()
        try JSONEncoder().encode(response).write(to: mutationURL)

        try LoupeCLI.reflect([
            mutationURL.path,
            "--source", sourceRoot.path,
            "--output", outputURL.path,
        ])

        let reflection = try JSONDecoder().decode(
            LoupeMutationReflection.self,
            from: Data(contentsOf: outputURL)
        )

        #expect(reflection.sourceCandidates.first?.path.hasSuffix("EditorTextView.swift") == true)
        #expect(reflection.sourceCandidates.first?.text.contains("NSUserInterfaceItemIdentifier(\"EditorTextView\")") == true)
        #expect(reflection.sourceCandidates.contains { $0.text.contains("let textView = EditorTextView") })
    }

    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("loupe-reflect-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func mutationResponseWithoutTestID() -> LoupeMutationResponse {
        let before = labelNode(textColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1))
        let after = labelNode(textColor: LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1))
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n22",
                typeName: "UILabel",
                role: "staticText",
                text: "Burger Point",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n17",
                typeName: "RestaurantsListCVCell",
                role: "cell",
                frame: LoupeRect(x: 15, y: 511, width: 372, height: 172)
            ),
            siblings: [
                LoupeMutationNodeSummary(ref: "n18", typeName: "UIImageView", role: "image"),
                LoupeMutationNodeSummary(ref: "n23", typeName: "UILabel", role: "staticText", text: "4.0"),
            ]
        )

        return LoupeMutationResponse(
            property: "textColor",
            selector: LoupeMutationSelector(kind: .ref, value: "n22"),
            value: .color(LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1)),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "swiggyclone-detail"
        )
    }

    private func mutationResponseForHeaderViewLabel() -> LoupeMutationResponse {
        let before = headerLabelNode(textColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1))
        let after = headerLabelNode(textColor: LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1))
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n52",
                typeName: "UILabel",
                role: "staticText",
                text: "Recent searches",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n51",
                typeName: "HeaderView",
                frame: LoupeRect(x: 0, y: 176, width: 402, height: 50)
            )
        )

        return LoupeMutationResponse(
            property: "textColor",
            selector: LoupeMutationSelector(kind: .ref, value: "n52"),
            value: .color(LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1)),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "upcomingmovies-search"
        )
    }

    private func mutationResponseForMessageKitMessageLabel() -> LoupeMutationResponse {
        let before = messageLabelNode(textColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1))
        let after = messageLabelNode(textColor: LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1))
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n48",
                typeName: "MessageLabel",
                role: "staticText",
                text: "Loupe chat ping",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n47",
                typeName: "MessageContainerView",
                role: "image",
                frame: after.frame
            ),
            ancestors: [
                LoupeMutationNodeSummary(
                    ref: "n40",
                    typeName: "TextMessageCell",
                    role: "cell",
                    frame: LoupeRect(x: 8, y: 35.67, width: 386, height: 108)
                ),
                LoupeMutationNodeSummary(
                    ref: "n16",
                    typeName: "MessagesCollectionView",
                    role: "collectionView",
                    frame: LoupeRect(x: 0, y: 0, width: 402, height: 874)
                ),
            ]
        )

        return LoupeMutationResponse(
            property: "textColor",
            selector: LoupeMutationSelector(kind: .ref, value: "n48"),
            value: .color(LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1)),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "messagekit-chat"
        )
    }

    private func mutationResponseForGenericContentViewLabelWithCellAncestor() -> LoupeMutationResponse {
        let before = labelNode(textColor: LoupeColor(red: 0, green: 0, blue: 0, alpha: 1))
        let after = labelNode(textColor: LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1))
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n195",
                typeName: "UITableViewLabel",
                role: "staticText",
                text: "SwitchRow",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n194",
                typeName: "UITableViewCellContentView",
                frame: LoupeRect(x: 0, y: 363, width: 319, height: 53)
            ),
            ancestors: [
                LoupeMutationNodeSummary(
                    ref: "n191",
                    typeName: "SwitchCell",
                    role: "cell",
                    frame: LoupeRect(x: 0, y: 363, width: 402, height: 53)
                ),
            ]
        )

        return LoupeMutationResponse(
            property: "textColor",
            selector: LoupeMutationSelector(kind: .ref, value: "n195"),
            value: .color(LoupeColor(red: 1, green: 0.2, blue: 0.4, alpha: 1)),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "eureka-rows"
        )
    }

    private func mutationResponseForSwiftUINavigationTitle() -> LoupeMutationResponse {
        let before = navigationTitleLabelNode(alpha: 1)
        let after = navigationTitleLabelNode(alpha: 0.35)
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n198",
                typeName: "UILabel",
                role: "staticText",
                text: "Setup",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n197",
                typeName: "_UINavigationBarLargeTitleView",
                frame: LoupeRect(x: 0, y: 132, width: 402, height: 52)
            )
        )

        return LoupeMutationResponse(
            property: "alpha",
            selector: LoupeMutationSelector(kind: .ref, value: "n198"),
            value: .double(0.35),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "harbour-setup"
        )
    }

    private func mutationResponseForSwiftUIHostingView() -> LoupeMutationResponse {
        let before = swiftUIHostingNode(alpha: 1)
        let after = swiftUIHostingNode(alpha: 0.92)
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n10",
                typeName: "LuminareWindowHostingView<LuminareWindowMeasuredContentView<ModifiedContent<SettingsContentView, _FrameLayout>>>",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n9",
                typeName: "LuminareWindowHostingContainerView",
                frame: after.frame
            ),
            siblings: [
                LoupeMutationNodeSummary(ref: "n86", typeName: "_NSThemeCloseWidget", role: "button", text: "Button"),
            ],
            children: [
                LoupeMutationNodeSummary(ref: "n11", typeName: "_NSGraphicsView"),
            ]
        )

        return LoupeMutationResponse(
            property: "alpha",
            selector: LoupeMutationSelector(kind: .ref, value: "n10"),
            value: .double(0.92),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "loop-settings"
        )
    }

    private func mutationResponseForSwiftUIListCellHostingView() -> LoupeMutationResponse {
        let before = swiftUIListCellHostingNode(alpha: 1)
        let after = swiftUIListCellHostingNode(alpha: 0.42)
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n96",
                typeName: "CellHostingView<ModifiedContent<_ViewList_View, CollectionViewCellModifier>>",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n95",
                typeName: "_UICollectionViewListCellContentView",
                frame: after.frame
            )
        )

        return LoupeMutationResponse(
            property: "alpha",
            selector: LoupeMutationSelector(kind: .ref, value: "n96"),
            value: .double(0.42),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "dime-categories"
        )
    }

    private func mutationResponseForAppKitEditorTextView() -> LoupeMutationResponse {
        let before = appKitEditorTextViewNode(alpha: 1)
        let after = appKitEditorTextViewNode(alpha: 0.52)
        let hierarchy = LoupeMutationHierarchyContext(
            target: LoupeMutationNodeSummary(
                ref: "n27",
                typeName: "EditorTextView",
                testID: "EditorTextView",
                text: "Loupe CotEditor sample",
                frame: after.frame
            ),
            parent: LoupeMutationNodeSummary(
                ref: "n26",
                typeName: "NSClipView",
                frame: LoupeRect(x: 672, y: 214, width: 608, height: 643)
            )
        )

        return LoupeMutationResponse(
            property: "alpha",
            selector: LoupeMutationSelector(kind: .testID, value: "EditorTextView"),
            value: .double(0.52),
            target: LoupeQueryResult(node: before),
            before: before,
            after: after,
            hierarchy: hierarchy,
            snapshotID: "coteditor-document"
        )
    }

    private func labelNode(textColor: LoupeColor) -> LoupeNode {
        LoupeNode(
            ref: "n22",
            parentRef: "n17",
            kind: .view,
            typeName: "UILabel",
            role: "staticText",
            text: "Burger Point",
            frame: LoupeRect(x: 119, y: 538, width: 91, height: 20),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(textColor: textColor)
        )
    }

    private func navigationTitleLabelNode(alpha: Double) -> LoupeNode {
        LoupeNode(
            ref: "n198",
            parentRef: "n197",
            kind: .view,
            typeName: "UILabel",
            role: "staticText",
            text: "Setup",
            frame: LoupeRect(x: 16, y: 135.67, width: 94.33, height: 40.67),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(alpha: alpha)
        )
    }

    private func appKitEditorTextViewNode(alpha: Double) -> LoupeNode {
        LoupeNode(
            ref: "n27",
            parentRef: "n26",
            kind: .view,
            typeName: "EditorTextView",
            text: "Loupe CotEditor sample",
            frame: LoupeRect(x: 672, y: 214, width: 608, height: 610),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(alpha: alpha),
            accessibility: LoupeAccessibility(
                identifier: "EditorTextView",
                value: "Loupe CotEditor sample",
                frame: LoupeRect(x: 672, y: 214, width: 608, height: 610)
            )
        )
    }

    private func swiftUIHostingNode(alpha: Double) -> LoupeNode {
        LoupeNode(
            ref: "n10",
            parentRef: "n9",
            kind: .view,
            typeName: "LuminareWindowHostingView<LuminareWindowMeasuredContentView<ModifiedContent<SettingsContentView, _FrameLayout>>>",
            frame: LoupeRect(x: 389, y: 138, width: 1142, height: 620),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(alpha: alpha)
        )
    }

    private func swiftUIListCellHostingNode(alpha: Double) -> LoupeNode {
        LoupeNode(
            ref: "n96",
            parentRef: "n95",
            kind: .view,
            typeName: "CellHostingView<ModifiedContent<_ViewList_View, CollectionViewCellModifier>>",
            frame: LoupeRect(x: 16, y: 182.33, width: 370, height: 60.33),
            isVisible: true,
            isEnabled: true,
            isInteractive: true,
            style: LoupeStyle(alpha: alpha)
        )
    }

    private func headerLabelNode(textColor: LoupeColor) -> LoupeNode {
        LoupeNode(
            ref: "n52",
            parentRef: "n51",
            kind: .view,
            typeName: "UILabel",
            role: "staticText",
            text: "Recent searches",
            frame: LoupeRect(x: 16, y: 184, width: 370, height: 34),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(textColor: textColor)
        )
    }

    private func messageLabelNode(textColor: LoupeColor) -> LoupeNode {
        LoupeNode(
            ref: "n48",
            parentRef: "n47",
            kind: .view,
            typeName: "MessageLabel",
            role: "staticText",
            text: "Loupe chat ping",
            frame: LoupeRect(x: 42, y: 73.67, width: 259, height: 37),
            isVisible: true,
            isEnabled: true,
            isInteractive: false,
            style: LoupeStyle(textColor: textColor)
        )
    }
}
