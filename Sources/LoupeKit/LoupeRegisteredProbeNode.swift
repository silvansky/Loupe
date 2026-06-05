import Foundation
import LoupeCore

func loupeRegisteredProbeNode(
    _ probe: LoupeRegisteredProbe,
    ref: String,
    parentRef: String,
    runtimeMetadata: [String: LoupeMetadataValue] = [:]
) -> LoupeNode {
    var custom = probe.metadata
    for (key, value) in runtimeMetadata {
        custom[key] = value
    }
    custom["synthetic"] = .bool(true)
    custom["observationBackend"] = .string("registered-probes")

    return LoupeNode(
        ref: ref,
        parentRef: parentRef,
        kind: .view,
        typeName: "LoupeRegisteredProbe",
        role: probe.role,
        testID: probe.id,
        label: probe.label,
        text: probe.label,
        frame: probe.frame,
        isVisible: probe.isVisible,
        isEnabled: probe.isEnabled,
        isInteractive: probe.isInteractive,
        accessibility: LoupeAccessibility(
            identifier: probe.id,
            label: probe.label ?? probe.id,
            traits: probe.isInteractive ? ["button"] : [],
            frame: probe.frame,
            activationPoint: probe.frame?.center,
            isElement: true
        ),
        custom: custom
    )
}
