# Loupe Goal

Loupe is a runtime E2E harness for iOS Simulator apps.

The project goal is:

1. Launch an app with Loupe observation injected or linked.
2. Capture a high-fidelity UIKit and accessibility tree from inside the app.
3. Let the CLI resolve stable selectors from that tree.
4. Execute simulator-visible input through runtime commands, without XCTest as
   the public harness.
5. Let the injected SDK and CLI communicate through localhost for snapshots,
   on-demand inspection, layout audits, logs, recording, and app-authored
   diagnostic events.
6. Record human or CLI-driven gesture flows and replay them as Loupe actions.
7. Let developers patch supported UIKit view properties at runtime so UI/design
   iteration can happen from the CLI without rebuilding the app.
8. Keep reproducible traces and smoke harnesses in the repository as the source
   of truth.

Current implementation stance:

- Loupe owns app-side observation, selector resolution, runtime logs, recording,
  on-demand inspection, allowlisted runtime property mutation, initial layout
  audit checks, screenshots, replay shape, and CLI UX.
- Low-level tap, drag, swipe, and type dispatch uses Loupe's native host-side
  HID backend.
