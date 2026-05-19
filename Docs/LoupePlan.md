# Loupe Plan

## Goals

Build an iOS Simulator harness that supports:

- functional E2E flows
- view-tree and property observation
- custom app metadata
- screenshot-based visual QA
- rule-based layout/style QA

Figma API integration is intentionally out of scope for now.

See `Docs/Goal.md` for the current runtime E2E goal contract.

## Architecture

```text
Host runner
  - starts simulator/app
  - stores full snapshots
  - sends compact observations to the LLM
  - executes actions through Loupe runtime commands
  - dispatches low-level input through Loupe's native HID backend
  - stores screenshots, diffs, logs, and traces

LoupeKit
  - captures UIWindowScene/UIWindow/UIView tree
  - captures structured UIKit and accessibility properties
  - exposes full node inspection and basic layout audit endpoints
  - exposes allowlisted runtime UIKit property mutation
  - exposes custom metadata
  - exposes runtime logs and touch recording
  - serves snapshots over localhost transport

LoupeInjector
  - simulator-only dynamic library
  - starts LoupeServer from a dylib constructor path
  - works for basic observation without linking LoupeKit into the app

Homebrew install
  - installs loupe CLI into bin
  - installs LoupeInjector.framework into libexec
  - lets loupe launch --inject resolve the injector path automatically

LoupeCore
  - Codable full snapshot
  - compact observation
  - selector queries
  - ref-based action targets
```

## Action Boundary

Loupe should not rely on app-internal private `UIEvent` synthesis as the primary
interaction mechanism. The app-side SDK and injector observe state. Host-side
runtime commands should execute interactions without requiring `xcodebuild test`,
XCTest cases, or a test bundle as the public harness.

The action backend may use lower-level simulator facilities or a dedicated host
process, but XCTest/XCUITest and WebDriverAgent-style runners are compatibility
or research backends, not the target product path.

The target flow is:

```text
loupe tap --test-id checkout.payButton
  -> fetch /snapshot
  -> resolve node frame
  -> execute simulator input through the runtime action backend
  -> store trace artifacts
```

The current proof for this flow has been productized into Loupe CLI runtime
actions. The older example UI test remains useful as a compatibility check, not
as the primary action architecture.

## Observation Policy

Do not put the whole tree into LLM context by default.

Default observation:

- screen size, scale, interface style
- visible texts, capped
- visible interactive elements, capped, including UIKit type/class identity
- per-snapshot `ref` values

Implemented host-side query primitives:

- `testID`
- `text`
- `role`
- `ref`

Later on-demand tools:

- `search(query)`
- `subtree(ref, depth)`
- `screenshotCrop(rect)`

Implemented on-demand detail tools:

- `inspect(ref/testID/text/role)` for the full node plus parent, siblings, and
  children summaries
- `audit(snapshot)` for sibling overlap and child-outside-parent issues

## Runtime Mutation

Loupe follows Lookin's high-level idea of resolving a runtime object and
applying a typed property update on the app main thread, but does not expose
arbitrary Objective-C selectors. The public shape is:

```bash
loupe set --test-id checkout.title text "New title"
loupe set --test-id checkout.card backgroundColor --color '#ff3366'
loupe set --test-id checkout.card frame --rect 20,120,220,80
loupe set --list
```

The injected server handles `POST /mutate` with a selector, property path, and
typed value. Supported properties are intentionally allowlisted: frame/bounds,
alpha, hidden, background/text/border colors, corner radius, accessibility
strings, label/button/text field text, font size, text alignment, and common
control values.

Mutation support is registry-based, not a single hard-coded switch. New UIKit
coverage should be added as a descriptor group in `LoupeAgent`: view, layer,
accessibility, text, control, scroll, stack, or another UIKit-family group. The
runtime `/mutations` endpoint and `loupe set --list` expose the active registry
so agents can discover support before editing a screen.

## Runtime Edit To Code Loop

The intended developer loop is:

```bash
loupe tree --udid <UDID> --view --depth 3
loupe set --udid <UDID> --test-id checkout.title text "Runtime title" --output /tmp/loupe-set.json
loupe fetch http://127.0.0.1:<port>/snapshot --output /tmp/loupe-after.json
loupe inspect /tmp/loupe-after.json --test-id checkout.title
loupe reflect /tmp/loupe-set.json --source ./Sources --output /tmp/loupe-reflect.json
```

`reflect` is advisory. It does not edit source files by itself; it returns
before/after summaries, target hierarchy context, and candidate files/lines
containing the stable test ID. The agent or developer then decides the smallest
matching source change and reruns Loupe verification.

## Validation Types

Functional E2E:

```swift
futureTap(ref)
type(ref, text)
swipe(ref, direction)
waitForVisible(testID)
```

Visual QA:

```swift
expectScreen("checkout.default").toMatchBaseline(threshold: 0.01)
```

Layout/style QA:

```swift
expect("checkout.payButton").toHaveFrame(height: 52)
expect("checkout.payButton").toHaveStyle(cornerRadius: 12)
expect("checkout.payButton").toBeBelow("checkout.password", spacing: 16)
```

## Next Implementation Steps

1. Expand native HID coverage for pinch and hardware-button events.
2. Add trace artifacts for every action: before/after snapshots, screenshots,
   target resolution, and logs.
3. Add screenshot capture and baseline diff storage.
4. Add richer selector scoring.
5. Expand layout/style assertion primitives.
6. Add a generated Codex skill/package release flow.
