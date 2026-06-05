---
name: loupe
description: Use this skill when working with Loupe Apple-platform runtime automation, simulator injection, linked LoupeInjector runtimes, view-tree inspection, accessibility tree querying, compact screen context, or Loupe CLI-driven platform actions.
---

# Loupe

Use Loupe to observe, query, act on, mutate, and diagnose Apple-platform app
runtimes through the in-process server.

## Core Rules

- Use grouped commands from current help: `app`, `ui`, `act`, and `debug`.
  Old top-level verbs are compatibility aliases only.
- Check subcommand help before adding flags; options are not shared globally.
- For this repository's current runtime/CLI changes, use `./.build/debug/loupe`
  plus a rebuilt local injector. Installed CLIs or injectors may be stale.
- Keep the attachment mode explicit: simulator injection, linked physical
  device runtime, macOS host runtime, watchOS, or visionOS.
- Keep full reports, snapshots, and traces on disk; send compact observations
  to agents, then query or inspect refs as needed.
- Prefer accessibility for discovery/action intent; prefer the view tree for
  layout, style, mutations, and visual diagnostics.
- Prefer `testID`, current-snapshot `ref`, or coordinates. Do not use
  tap-by-text as a public contract.
- Command success alone is not proof. Verify with fresh reports, traces,
  screenshots, hit-tests, logs, defaults, or effective state.
- Repository examples should stay import-free when injection can cover the
  workflow; do not add `import LoupeKit` just to make simulator examples pass.

## References

- `references/runtime-modes.md`: attaching, launching, platform boundaries.
- `references/evidence-workflow.md`: reports, visibility, SwiftUI, probes,
  logs, diagnostics.
- `references/actions-and-mutations.md`: actions, waits, scrolls, mutations,
  self-sizing, `reflect`.

## Default Loop

1. Identify the runtime mode and host. Prefer the host printed by `app launch`;
   `app current` can be stale.
2. Capture `ui report` and keep `snapshot.json`.
3. Discover with text/role/accessibility, then switch to `testID` or a ref from
   the same snapshot. Inspect with `ui node` before acting.
4. For overlays, alerts, reused cells, or stale refs, recapture and use
   hit-test, responder-chain, screenshot, or trace proof.
5. Act or mutate with a fresh output/trace path, then prove the result with a
   fresh report, query, node, trace, or effective-state check.

## Blind Validation Prompt

For a context-free agent, include only this skill, current help, and a compact
contract:

```text
Run Loupe only through the provided executable and grouped command surface.
Host setup/cleanup tools named in the contract are allowed.
Provide: CLI path, help checked, app/build path, bundle id, device or UDID,
attachment mode, host/port, injector path when used, source root, starting
screen, scenario, expected evidence, allowed source edits.

Required evidence:
- host, report/snapshot path, compact or screen summary, targeted query/node
- trace/output dirs plus fresh after-proof for each claimed change
- screenshot-visible and queryable SwiftUI/bridge evidence kept separate
- mutation output, effective-state proof, and reflect output when useful
- exact unresolved gaps
```
