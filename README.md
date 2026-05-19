# Loupe

<p align="center">
  <img src="Docs/Assets/loupe-logo.svg" alt="Loupe" width="160">
</p>

Runtime E2E inspection and action harness for iOS Simulator apps.

Loupe starts a small HTTP server inside the simulator app process, captures
UIKit and accessibility state on demand, and dispatches simulator input through
its native HID backend.

## Install

```bash
brew tap heoblitz/loupe https://github.com/heoblitz/Loupe.git
brew install loupe
```

## Start

Build and install your iOS app on a simulator, then launch it through Loupe:

```bash
loupe start --bundle-id com.example.App --device booted
loupe runtime --udid booted
```

`start` injects Loupe into the app and waits for the in-app runtime server. When
multiple simulators are booted, pass the exact simulator UDID.

## Observe

```bash
loupe tree --udid <UDID> --accessibility --depth 3
loupe tree --udid <UDID> --view --depth 3
loupe fetch http://127.0.0.1:8765/snapshot --output snapshot.json
loupe inspect snapshot.json --test-id checkout.payButton
loupe compact snapshot.json
```

Use the accessibility tree for movement and input targets. Use the view tree for
layout, UIKit properties, color, size, and design checks.

## Act

```bash
loupe tap --udid <UDID> --test-id checkout.payButton --expect-visible checkout.confirmation
loupe tap --udid <UDID> --ref n83
loupe tap --udid <UDID> --x 201 --y 274
loupe swipe --udid <UDID> --from 220,760 --to 220,190
loupe type "Ada" --udid <UDID>
```

## Debug

```bash
loupe trace-summary /tmp/loupe-trace
loupe diff /tmp/loupe-trace/before-snapshot.json /tmp/loupe-trace/after-snapshot.json
loupe audit snapshot.json
loupe compare-design snapshot.json figma-export.json
```

Failed actions automatically write traces under the system temporary
`loupe-traces` directory. Successful traced actions include `target-crop.png`
when Loupe resolved a framed target.

## Mutate

```bash
loupe tree --udid <UDID> --view --depth 3
loupe set --udid <UDID> --test-id checkout.title text "Runtime title" --output mutation.json
loupe inspect snapshot.json --test-id checkout.title
loupe reflect mutation.json --source ./Sources
loupe set --udid <UDID> --test-id checkout.card backgroundColor --color '#ff3366'
loupe set --udid <UDID> --test-id checkout.card frame --rect 20,120,220,80
loupe set --udid <UDID> --list
```

`set` updates allowlisted UIKit properties inside the injected app process.
`reflect` turns a mutation response into before/after summaries, hierarchy
context, and source candidates so an agent can decide the smallest matching code
change.

## Record

```bash
loupe record start checkout-flow --udid <UDID>
loupe record stop --udid <UDID>
loupe replay checkout-flow --udid <UDID> --width 438 --height 954
```

## Maintenance

```bash
loupe skills install
loupe cleanup --dry-run
loupe cleanup
```

`skills install` upserts the Loupe skill into existing Codex or Claude Code
skill folders. `cleanup` removes stale runtime records and old trace bundles;
recordings are preserved unless explicitly requested.

## Verify

```bash
swift test
Examples/LoupeExample/run-bookmark-e2e.sh
```

## Docs

- [Status](Docs/Status.md)
- [Test Plan](Docs/TestPlan.md)
- [Runtime Communication](Docs/RuntimeCommunication.md)
- [Homebrew Distribution](Docs/Homebrew.md)
- [Development Homebrew Overlay](Docs/DevHomebrewOverlay.md)

## Inspiration

Loupe's simulator inspection and action direction is inspired by
[AXe](https://github.com/cameroncooke/AXe) and
[Baguette](https://github.com/tddworks/baguette).
