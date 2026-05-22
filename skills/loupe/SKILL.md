---
name: loupe
description: Use this skill when working with iOS Simulator UI automation, Loupe runtime injection, view-tree inspection, accessibility tree querying, compact screen context, or Loupe CLI-driven simulator actions.
---

# Loupe

Use Loupe for iOS Simulator runtime observation, UI actions, optional mutation
experiments, and design-quality feedback. Keep full snapshots on disk; send
compact reports, trees, maps, and targeted `inspect` output to agents.

## Rules

- Use the installed `loupe`; resolve injector paths with `loupe injector-path`.
- Loupe runs through the injected app server; no separate host daemon is needed.
- Use accessibility for text discovery and action targets. Use the view tree for
  layout, style, UIKit properties, mutation refs, and design checks.
- Use Loupe CLI actions for runtime E2E. Do not make XCTest or a UI test bundle
  the public harness.
- Public actions are `tap`, `swipe`, `drag`, and `type`. Avoid tap-by-text as a
  main interface; prefer `testID`, `ref`, or coordinates. `pinch` is not
  implemented.

## Start Or Select Runtime

For a built app:

```bash
xcrun simctl install booted /path/to/App.app
loupe start --bundle-id com.example.App
```

When multiple apps are injected, select the runtime before probing. For `use`,
only call `loupe use <bundle-id>` or `loupe use --host <runtime-host>`. Put
`--bundle-id`, `--udid`, and `--host` on observation/action commands when you
need an explicit target. Do not keep retrying the default host after
`loupe runtimes` shows another host.

```bash
loupe runtimes
loupe use com.example.App
loupe use --host <runtime-host>
loupe current
```

## Observe With Low Context

Start broad, then inspect only specific refs or test IDs:

```bash
loupe capture-report --bundle-id com.example.App --output /tmp/loupe-report
loupe fetch <runtime-host>/snapshot --output /tmp/loupe-snapshot.json
loupe compact /tmp/loupe-snapshot.json
loupe tree /tmp/loupe-snapshot.json --accessibility --depth 3
loupe tree /tmp/loupe-snapshot.json --view --depth 3
loupe screen-map /tmp/loupe-snapshot.json --limit 80
loupe inspect /tmp/loupe-snapshot.json --test-id target.id
```

Use `capture-report` when screenshots matter; it stores screenshot, snapshot,
screen-map, accessibility, compact, audit, runtime, and summary artifacts
together. Use `screen-map` for visible semantic/styled elements. Use
`paint-stack` when a visual change appears covered. Use `audit`, `subtree`,
`query`, and `text-map` only when they answer the next concrete question.

If shallow trees only show containers, retry with depth 6-8 or use:

```bash
loupe tree --accessibility --text
loupe tree --interesting
loupe tree --visible-leaves
```

## Act And Verify

```bash
loupe tap --test-id checkout.payButton --udid booted --trace-dir /tmp/loupe-trace --expect-visible checkout.confirmation
loupe tap --snapshot /tmp/loupe-snapshot.json --ref n21 --udid booted
loupe tap --x 201 --y 274 --udid booted --width 438 --height 954
loupe swipe --from 219,760 --to 219,190 --udid booted --width 438 --height 954 --trace-dir /tmp/loupe-trace
loupe drag --from 4,420 --to 360,420 --udid booted --duration 0.8
loupe type "Ada" --udid booted
loupe trace-summary /tmp/loupe-trace
loupe diff /tmp/loupe-trace/before-snapshot.json /tmp/loupe-trace/after-snapshot.json --changed-only
loupe explore-routes --bundle-id com.example.App --limit 5 --trace-dir /tmp/loupe-routes --output /tmp/loupe-routes.json --json
```

Failed actions write traces under `/tmp/loupe-traces`. For scroll gestures,
treat a successful HID response with no offset or visible-frame change as a
failed action unless you intentionally pass `--no-verify-scroll`. Use
`explore-routes` for a route sweep; use `trace-summary` on individual action
trace directories, not on the route report root.

## Runtime Mutation

Mutations are optional developer-only experiments against the injected runtime.
Prefer stable `testID`; use `ref` only within the same observed screen. Text,
colors, alpha, hidden state, layer styling, and common control values are better
targets than layout-owned frame changes.

```bash
loupe mutations --test-id example.design.card
loupe set --test-id example.design.card backgroundColor --color '#ff3366' --output /tmp/loupe-set.json
loupe set --test-id example.design.card frame --rect 20,120,220,80 --no-animate --output /tmp/loupe-set.json
loupe set-many --refs n21,n22 backgroundColor --colors FFE4E6_1 FFE8CC_1 --trace-dir /tmp/loupe-set-many
loupe wait-for-value --test-id example.design.card --key style.backgroundColor.red --equals 1 --output /tmp/loupe-wait.json
loupe reflect /tmp/loupe-set.json --source ./Sources
```

Property mutations animate by default; use `--no-animate` when verification
needs immediate state. Treat frame and Auto Layout mutations as probes unless
the effective state confirms UIKit kept the requested value.

## Design Quality Loop

When implementing from Figma, screenshots, or visual references, use Loupe
artifacts to reject bad runtime UI and iterate. Screenshots are necessary, but
the view tree is the structured source of truth.

```bash
loupe capture-report --bundle-id com.example.App --output /tmp/loupe-report
loupe screen-map /tmp/loupe-report/snapshot.json --limit 120
loupe tree /tmp/loupe-report/snapshot.json --view --depth 6
loupe inspect /tmp/loupe-report/snapshot.json --test-id key.control
loupe audit /tmp/loupe-report/snapshot.json
loupe screenshot --udid booted --output /tmp/loupe-screen.png
loupe tap --test-id key.control --udid booted --trace-dir /tmp/loupe-trace
```

Before declaring success, compare a small anchor table: screen/root, primary
title, first major image/card, fixed chrome, and at least one scroll container.
Fix the largest frame or hierarchy miss before polishing small visual details.

Reject and fix when screen size is wrong, simulator chrome is duplicated, fixed
chrome scrolls with content, carousel axis or scroll behavior is wrong, key
text/frame/color/corner radius/clipping metadata is wrong, a route cannot be
traced, or the screenshot is not the intended app state. Visual-heavy screens
should use native structure plus leaf media assets, not a full-screen screenshot
as the UI.

Use `Docs/FigmaComparison.md` for fixture-based `compare-design` data. Match by
`testID` first, then role plus text, then geometry.

## Debug

```bash
loupe doctor
loupe injector-path
loupe cleanup --dry-run
```

If injection does not start the server, confirm the app is running in Simulator,
the injector path is executable, relaunch with `loupe launch --bundle-id <id>
--inject`, then check `loupe current` and `<runtime-host>/health`.
