@testable import LoupeCLI
import Foundation
import LoupeCore
import Testing

@Suite struct MutationCapabilitiesTests {
    @Test func appKitSwiftUIPopupButtonDoesNotAdvertiseUIKitTextStyleMutations() {
        let output = LoupeCLI.renderNodeMutationCapabilities(
            node(
                className: "SwiftUIPopupButton",
                role: "button",
                text: "Dot",
                button: LoupeUIButtonProperties(),
                control: LoupeUIControlProperties(controlState: "enabled")
            )
        )
        let supported = supportedProperties(in: output)

        #expect(supported.contains("text"))
        #expect(supported.contains("title"))
        #expect(supported.contains("fontSize"))
        #expect(!supported.contains("textColor"))
        #expect(!supported.contains("textAlignment"))
        #expect(!supported.contains("lineBreakMode"))
    }

    @Test func uiKitButtonStillAdvertisesButtonTextStyleMutations() {
        let output = LoupeCLI.renderNodeMutationCapabilities(
            node(
                className: "UIButton",
                role: "button",
                text: "Save",
                button: LoupeUIButtonProperties(lineBreakMode: "byTruncatingTail"),
                control: LoupeUIControlProperties(controlState: "enabled")
            )
        )
        let supported = supportedProperties(in: output)

        #expect(supported.contains("text"))
        #expect(supported.contains("title"))
        #expect(supported.contains("textColor"))
        #expect(supported.contains("fontSize"))
        #expect(supported.contains("lineBreakMode"))
    }

    @Test func appKitTextFieldDoesNotAdvertiseUIKitOnlyTextMutations() {
        let output = LoupeCLI.renderNodeMutationCapabilities(
            node(
                className: "NSTextField",
                role: "staticText",
                text: "General",
                label: LoupeUILabelProperties(numberOfLines: 1),
                textField: LoupeUITextFieldProperties()
            )
        )
        let supported = supportedProperties(in: output)

        #expect(supported.contains("text"))
        #expect(supported.contains("textColor"))
        #expect(supported.contains("fontSize"))
        #expect(!supported.contains("textAlignment"))
        #expect(!supported.contains("numberOfLines"))
        #expect(!supported.contains("placeholder"))
        #expect(!supported.contains("secureTextEntry"))
    }

    private func node(
        className: String,
        role: String,
        text: String,
        label: LoupeUILabelProperties? = nil,
        button: LoupeUIButtonProperties? = nil,
        textField: LoupeUITextFieldProperties? = nil,
        textView: LoupeUITextViewProperties? = nil,
        control: LoupeUIControlProperties? = nil
    ) -> LoupeNode {
        LoupeNode(
            ref: "n1",
            parentRef: nil,
            kind: .view,
            typeName: className,
            role: role,
            text: text,
            frame: LoupeRect(x: 0, y: 0, width: 120, height: 32),
            isVisible: true,
            isEnabled: true,
            isInteractive: control != nil || button != nil,
            uiKit: LoupeUIKitProperties(
                className: className,
                tag: 0,
                alpha: 1,
                isHidden: false,
                isOpaque: false,
                clipsToBounds: false,
                userInteractionEnabled: true,
                isFirstResponder: false,
                control: control,
                label: label,
                button: button,
                textField: textField,
                textView: textView
            )
        )
    }

    private func supportedProperties(in output: String) -> Set<String> {
        guard let line = output.split(separator: "\n").first(where: { $0.hasPrefix("supported: ") }) else {
            return []
        }
        return Set(
            line
                .dropFirst("supported: ".count)
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
    }
}
