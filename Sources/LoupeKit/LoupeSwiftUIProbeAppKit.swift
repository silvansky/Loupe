import Foundation
import LoupeCore

#if canImport(SwiftUI) && canImport(AppKit)
import AppKit
import SwiftUI

public extension View {
    /// Adds an AppKit probe view that Loupe can capture as a stable `ui node`.
    func loupeProbe(_ id: String, label: String? = nil) -> some View {
        background {
            LoupeSwiftUIProbeRepresentable(id: id, label: label)
        }
    }
}

private struct LoupeSwiftUIProbeRepresentable: NSViewRepresentable {
    var id: String
    var label: String?

    func makeNSView(context: Context) -> NSView {
        LoupeAppKitSwiftUIProbeBackingView.make(id: id, label: label)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        LoupeAppKitSwiftUIProbeBackingView.update(nsView, id: id, label: label)
    }
}

@MainActor
enum LoupeAppKitSwiftUIProbeBackingView {
    static func make(id: String, label: String?) -> NSView {
        let view = NSView()
        update(view, id: id, label: label)
        return view
    }

    static func update(_ nsView: NSView, id: String, label: String?) {
        nsView.testID(id)
        nsView.testProperty("loupe.probe", true)
        nsView.setAccessibilityElement(true)
        nsView.setAccessibilityLabel(label ?? id)
        nsView.setAccessibilityRole(.group)
        nsView.wantsLayer = true
        nsView.layer?.backgroundColor = NSColor.clear.cgColor
    }
}
#endif
