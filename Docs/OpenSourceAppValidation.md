# Open-Source App Validation Queue

This queue is for real-app Loupe validation. It is not a showcase list. Each
candidate should produce a concrete main-agent task, a blind subagent task, and
one of these outcomes:

- Loupe works smoothly with evidence.
- Loupe works, but the skill needs clearer guidance.
- Loupe runtime or CLI needs a general fix.
- The app is not a useful validation target because build/auth/setup dominates
  the UI loop.

Use real app screens over component demo apps. Component examples are useful
only when isolating a runtime bug found in a real app.

## Protocol

For each app:

1. Clone or update the app outside this repository, usually under
   `/tmp/loupe-open-source-candidates`.
2. Record the exact build command, bundle ID, simulator/device UDID, attachment
   mode, and injector path.
3. Main agent captures the first report and writes a minimal task contract.
4. Blind subagent receives only the Loupe skill, current `loupe help`, and that
   task contract.
5. Blind subagent must use grouped commands only: `app`, `ui`, `act`, and
   `debug`.
6. After every action, recapture or trace before drawing conclusions.
7. Any skill or runtime change must generalize beyond the app being tested.

Required command coverage should include as many of these as the app makes
meaningful:

- `loupe app launch`, `app current`, `app list`
- `loupe ui report`, `compact`, `screen`, `tree`, `query`, `node`, `audit`
- `loupe ui hit-test`, `responder-chain`
- `loupe act tap`, `swipe`, `drag`, `type`, `wait`
- `loupe debug logs`, `network`, `trace summary`, `trace diff`, `scroll`
- `loupe ui mutations`, `set`, `set-many`, `reflect`

## Current Coverage Snapshot

Updated: 2026-06-05.

The queue already has at least five candidate apps per platform slice. Continue
new loops only when they add a new boundary or command path; otherwise tighten
the skill/runtime around the seed cases below.

| Platform slice | Candidate count | Validated seed coverage | Next useful loop |
| --- | ---: | --- | --- |
| iOS SwiftUI | 7 | Ice Cubes, OpenScanner, Dime, Steps, Harbour, V2exOS iOS | Re-run blind validation for Harbour if stale; otherwise target a new form/list boundary. |
| iOS UIKit | 6 | Expense Tracker, SwiggyClone, IGListKit, Eureka, MessageKit, UpcomingMovies | Use only for regressions around secure fields, reused cells, self-sizing, or reflection ranking. |
| macOS AppKit | 5 | SwiftTerm MacTerminal, CotEditor, Equinox, LocationSimulator | Prefer editor/table/window cases; keep external device or file workflows read-only. |
| macOS SwiftUI | 6 | Loop, Ice, Yattee; Gifski is currently blocked by local Xcode project compatibility | Use Yattee for sparse SwiftUI semantics, list activation boundaries, and testID-backed mutation/reflect regressions. |
| tvOS | 6 | V2exOS TV, Swiftfin, News tvOS, Cronica | Add only new focus/input boundaries; thin command coverage now has SwiggyClone seed evidence. |
| watchOS | 5 | Gym Routine Tracker Watch, SafeTimer Watch, Magic Tap Watch, Brush Watch | Keep registered probes sparse and prove route/state changes with stabilized reports, screenshots, logs, or defaults. |
| visionOS | 6 | HandsRuler, PersonaChess, OpenImmersive | Do not overclaim spatial action success; current value is observation, probes, hit-test, and screenshot/state evidence. |

Thin command coverage now has real-app seed evidence for `debug scroll`,
`act wait`, and `act drag` through SwiggyClone. Add more only when a new app has
a drag-specific before/after state such as carousel offset, scrubber movement,
or canvas/object repositioning.

Candidate count is the backlog pool below; validated seed coverage is the set
of completed main-agent plus blind-agent loops.

## Seed Case

### Ice Cubes

- Repo: https://github.com/Dimillian/IceCubesApp
- Revision: `0fc41d2ced2e3e735bd9c42d5ae6dea16e63d618`
- Platforms: iOS, iPadOS, macOS, visionOS
- UI: SwiftUI over UIKit/AppKit host views
- Why it matters: real account-add flow, SwiftUI lists, text input, system
  notification alert, network-backed recommended server cards.
- First verified scenario: iOS Simulator injection, account-add screen, server
  URL text field, notification permission alert, ref-based text entry, and
  network-backed server-info refresh.
- Build command:
  `xcodebuild -project IceCubesApp.xcodeproj -scheme IceCubesApp -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-icecubes-ios CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM= BUNDLE_ID_PREFIX=com.example build`
- Bundle ID: `com.example.IceCubesApp`
- Main-agent evidence:
  - `app launch --inject` opened `http://127.0.0.1:28795` on
    `C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7`.
  - `ui report` decoded a real SwiftUI app snapshot successfully.
    Artifacts:
    `/tmp/loupe-icecubes-report-initial`,
    `/tmp/loupe-icecubes-report-after-alert`, and
    `/tmp/loupe-icecubes-report-typed`.
  - `ui query --exact-text '서버 URL' --tree accessibility --include-hidden`
    found the localized server URL text field at `ax-n405`.
  - The screenshot saw the system permission alert, while in-app hit-test saw
    the covered app content. The skill must tell agents to handle system alerts
    with screenshot and host/simulator evidence, not app view-tree assumptions.
    In this run, a native coordinate tap on the visible `허용 안 함` button
    dismissed the alert; the proof is the fresh screenshot, not app query.
  - Same-snapshot `act tap --ref ax-n405 --snapshot ... --backend native`
    targeted the text field, and `act type 'mastodon.social'` changed the value.
    A fresh `ui query --exact-text 'mastodon.social' --tree accessibility`
    returned the new text field value at `ax-n408`.
  - Typing `mastodon.social` triggered a real network-backed server-info
    refresh in the screenshot. The resulting visible `로그인`, `Mastodon`, and
    server-info labels were not queryable by text; the view tree mainly exposed
    SwiftUI list/hosting cells and the text field value. This is a useful
    SwiftUI semantic boundary, not a blank app.
  - `ui audit` produced findings on SwiftUI/SwiftUI-hosted UIKit internals such
    as list header `CellHostingView`, `_UIBarBackground`, `AnimationView`, and
    the `UITextField`. For real SwiftUI apps, audit findings need
    source/role/frame triage before they are treated as app defects.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same boundary: app runtime query found `서버 URL`, app-side hit-test at
    alert button coordinates returned the covered app cell, and after-tap
    screenshot still showed the system alert. Artifacts:
    `/tmp/loupe-icecubes-blind-validation-20260605`.
  - Current blind validation also reproduced the full positive path with only
    the skill and target contract: permission alert present in screenshot but
    absent from app queries, native coordinate dismissal, same-snapshot text
    field ref tap, `act type mastodon.social`, and fresh server-detail
    screenshot/report. Artifacts:
    `/tmp/loupe-icecubes-blind-validation-20260605-current`.
  - The blind agent also found that the installed `loupe` on `PATH` exposed the
    older flat command surface. Worktree validation should use
    `./.build/debug/loupe` plus the rebuilt local injector.
- General fixes produced:
  - Core decodes legacy synthetic `tabBarItem` node kinds as view nodes.
  - Core defaults missing legacy `custom` and `children` node fields.
  - `ui tree --view` traverses hidden structural containers so a hidden scene
    node does not hide visible windows and SwiftUI-hosted views.
  - Skill now warns about stale global injectors, snapshot-scoped refs, grouped
    commands, overlay/system-alert checks, and noisy SwiftUI-hosted audit
    results.
  - Current skill guidance also tells agents to treat screenshot-visible
    SwiftUI text as visual evidence until `ui query`, `ui screen`, or
    app-authored identifiers prove it is structurally queryable.
  - `app launch` help now says `--device <sim|device|udid>` and explicitly
    warns that working-tree validation should set `LOUPE_INJECTOR_PATH` because
    injector resolution may otherwise use an installed Homebrew injector.

### OpenScanner

- Repo: https://github.com/pencilresearch/OpenScanner
- Revision: `6336c2cba1cac759f3f14bc306b4569ac6bfe494`
- Platform: iOS SwiftUI on UIKit hosts
- UI: document-scanner home screen with SwiftUI `.searchable`, a floating
  search bar, a floating scan button, and UIKit search-field internals.
- Why it matters: a real SwiftUI utility app exposed overlapping floating
  controls, sparse initial semantic discovery, focused `.searchable` text
  fields whose raw UIKit visibility is false, and a SwiftUI-created platform
  view mutation with no source-reflection candidate.
- Build command:
  `xcodebuild -project openscanner.xcodeproj -scheme scanner -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-openscanner-ios CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `camp.user.openscanner`
- External-only automation patch:
  - Updated `scanner/AppIntents.swift` so every App Shortcut phrase includes
    `${applicationName}` as required by the current Xcode metadata extractor.
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id camp.user.openscanner --inject --port 28766 --timeout 40`
- Evidence:
  - The initial report at `/tmp/loupe-openscanner-ios-report-main` captured a
    real screenshot with the scanner home screen, bottom floating search bar,
    and scan button. The snapshot had `102` nodes, `13` accessibility nodes,
    `15` screen-map elements, `12` interactive elements, and `auditIssues: 0`.
  - Default semantic discovery was sparse: `ui query --text Search`,
    `ui query --text Scanner`, and `ui query --role button` did not find the
    screenshot-visible floating controls. Use screenshot plus hit-test evidence
    before acting on this kind of SwiftUI overlay.
  - Hit-tests around the visible scan/search area landed on
    `UISearchBarTextField`, `UIPlatformGlassInteractionView`,
    `CellHostingView`, or `FloatingBarHostingView` depending on the point.
    A successful native coordinate tap near the scan button did not prove a
    scanner route transition, so this remains an unproven action path.
  - Native focus on the floating search field followed by `act type 'invoice'`
    changed the runtime value. The trace summary showed
    `UISearchBarTextField text="Search" -> "Invoice"` and the list content
    size shrank to the filtered state.
  - The focused search field appeared in the raw snapshot as
    `UISearchBarTextField` with `isVisible=false`, `isFirstResponder=true`,
    and text `Invoice`. After the surface-visibility fix, default
    `ui query --text Invoice`, `ui query --role textField`, `ui compact`,
    `ui screen`, and `ui node --ref n70` all expose the active field with
    effective current-surface visibility.
  - Re-running audit before mutation produced `issueCount: 0`; the standard
    38pt `UISearchBarTextField` no longer counts as an app small-target
    defect.
  - `ui set --snapshot ... --ref n70 textColor --color '#ff3366'` changed the
    visible search text. A fresh report at
    `/tmp/loupe-openscanner-ios-report-after-textcolor-mutation` showed the
    red text color and an expected low-contrast issue from the deliberate
    mutation.
  - `ui reflect` on the mutation returned `sourceCandidates: []`, which is a
    bounded result for a UIKit search field created by SwiftUI `.searchable`
    with no stable app class or test ID.
  - Fresh blind validation with only the Loupe skill and target contract
    reproduced the main useful loop on port `28931`. Artifacts:
    `/tmp/loupe-openscanner-blind-IulXOn`. The blind run confirmed initial
    screenshot-visible lower `Search` and scan controls were absent from
    default view/accessibility text queries, while
    `--include-hidden --tree accessibility` exposed `ax-n94` as a hidden
    text-field anchor. `ui hit-test --point 200,822` resolved the search field,
    coordinate focus made `UISearchBarTextField` `isFirstResponder=true`,
    `act type "loupe"` produced a fresh `Loupe` value, text-color mutation
    changed the effective color to red, and `ui reflect` correctly returned
    `sourceCandidates: []`.
- General fixes produced:
  - Surface visibility now treats an on-screen first-responder text field/text
    view as discoverable even when raw platform `isVisible` is false.
  - `ui node` inspection uses the same offscreen-aware surface visibility as
    query discovery, so active SwiftUI search fields can be inspected without
    `--include-hidden`; use `--include-hidden` only when raw snapshot
    visibility is the thing being diagnosed.
  - Layout audit ignores standard no-testID `UISearchBarTextField` small-target
    noise while preserving deliberate contrast findings after mutations.

### Dime

- Repo: https://github.com/rafsoh/dimeApp
- Revision: `0463cb8caba237de781ae02e70a2ec82ae900c67`
- Platform: iOS SwiftUI on UIKit hosts
- UI: personal-finance onboarding with category selection, SwiftUI `List`
  backed by `UICollectionViewCompositionalLayout`, custom bottom controls,
  CloudKit/Core Data setup, and widget/IAP dependencies.
- Why it matters: a real finance app exposed entitlement-driven startup
  crashes before Loupe could observe the UI, screenshot-visible SwiftUI text
  with sparse semantic trees, coordinate-only onboarding actions, list
  structure/audit evidence, and a SwiftUI-generated cell mutation whose source
  reflection should return no weak candidate.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/dimeApp/app/dime.xcodeproj -scheme dime -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-dime-ios -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.rafaelsoh.dime`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id com.rafaelsoh.dime --inject --port 28781 --timeout 45 --env LOUPE_DISABLE_CLOUDKIT=1`
- External-only automation patches:
  - `DataController.swift` skips `NSPersistentCloudKitContainerOptions` when
    `LOUPE_DISABLE_CLOUDKIT=1`; unsigned simulator builds otherwise crash for
    missing CloudKit entitlements.
  - `LogView.swift` avoids `CloudKitSyncMonitor.SyncMonitor.shared` under the
    same variable; otherwise SwiftUI body construction aborts while querying
    CloudKit account status.
- Evidence:
  - Without the external-only CloudKit bypass the app crashed before a stable
    runtime was available. Crash reports showed `PFCloudKitContainerProvider`
    and then `CloudKitSyncMonitor.SyncMonitor.updateiCloudAccountStatus()`;
    the Loupe server thread had loaded, but the app main thread aborted.
  - After launch, initial report
    `/tmp/loupe-dime-ios-report-main` captured a clear onboarding screenshot
    with `Dime`, finance bullets, and `Get Started`, but the snapshot had only
    `57` nodes, `2` accessibility nodes, `1` screen-map element, and
    `visibleTexts: 0`. Treat this as a semantic coverage boundary, not a blank
    app.
  - Because `Get Started` was not queryable by text/ref, a coordinate
    `act tap --x 201 --y 810 --host http://127.0.0.1:28781 --udid C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --backend auto --trace-dir /tmp/loupe-dime-ios-trace-get-started`
    was used. The trace diff showed the onboarding host disappearing and
    category-list cells appearing; fresh report
    `/tmp/loupe-dime-ios-report-after-start` showed the category selection
    screen.
  - The category screen still had `visibleTexts: 0`, but exposed useful UIKit
    structure: `UpdateCoalescingCollectionView`,
    `ListCollectionViewCell`, and `CellHostingView`. `ui audit` reported two
    `smallInteractiveTarget` hints for 40.33pt section headers.
  - A coordinate tap on the visible Food plus button changed app state:
    `/tmp/loupe-dime-ios-trace-add-food` showed the collection content size
    changing `402,1002.22 -> 402,843.86`, cells reflowing, and the bottom tab
    tint changing. Fresh screenshot
    `/tmp/loupe-dime-ios-report-after-food/screenshot.png` showed Food moved
    into the selected expense category area and the next button enabled.
  - `ui set --snapshot /tmp/loupe-dime-ios-report-after-food/snapshot.json --ref n96 alpha 0.42 ...`
    changed a SwiftUI list cell host. Fresh `ui node` at
    `/tmp/loupe-dime-ios-report-after-alpha/snapshot.json` confirmed both
    `style.alpha` and `uiKit.alpha` as `0.41999998688697815`.
  - `ui reflect` for that mutation now returns `sourceCandidates: []`. That is
    the correct bounded result because the hierarchy only contains SwiftUI
    infrastructure names such as `CellHostingView<ModifiedContent<_ViewList_View,
    CollectionViewCellModifier>>` and no app-owned SwiftUI type or test ID.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same flow on port `28783`. Artifacts:
    `/tmp/loupe-dime-blind-report-main`,
    `/tmp/loupe-dime-blind-trace-get-started`,
    `/tmp/loupe-dime-blind-report-after-start`,
    `/tmp/loupe-dime-blind-trace-add-food`,
    `/tmp/loupe-dime-blind-report-after-food`,
    `/tmp/loupe-dime-blind-set-alpha.json`,
    `/tmp/loupe-dime-blind-report-after-alpha`, and
    `/tmp/loupe-dime-blind-reflect-alpha.json`. The blind run confirmed
    `visibleTexts: 0`, sparse accessibility, coordinate/hit-test driven action
    proof, `contentSize` reflow after Food selection, effective alpha
    `0.3499999940395355`, and `sourceCandidates: []`.
- General fixes produced:
  - `ui reflect` keeps app-owned inner SwiftUI generic types such as
    `SettingsContentView`, but filters SwiftUI runtime wrapper names such as
    `ModifiedContent`, `CellHostingView`, `_ViewList_View`, and
    `CollectionViewCellModifier` from strong hierarchy source hints.
  - `ui reflect` no longer returns weak property-only candidates for common
    visual properties such as `alpha` when there is no app type, test ID, or
    literal context.

### Steps

- Repo: https://github.com/brittanyarima/Steps
- Revision: `c043f9ec74a545c9a881e525fe4290ef3dab4064`
- Platform: iOS SwiftUI on UIKit hosts
- UI: HealthKit/Core Data step tracker with a tab view, SwiftUI `List`,
  bottom sheet goal creation, text entry, and a Widget extension.
- Why it matters: a real SwiftUI utility app exposed package/toolchain drift,
  widget bundle-ID install constraints, screenshot-visible SwiftUI buttons that
  are not text-queryable, and a persisted SwiftUI `List` row whose visible text
  is absent from the runtime snapshot.
- Build command:
  `xcodebuild -quiet -project /tmp/loupe-open-source-candidates/Steps/Steps.xcodeproj -scheme Steps -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-steps-ios -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64 clean build`
- Bundle ID: `com.example.Steps`
- External-only automation patches:
  - The resolved `swift-dependencies-additions` checkout under
    `/tmp/loupe-build-steps-ios/SourcePackages/checkouts` needed its
    `DependenciesAdditionsBasics` proxy `wrappedValue` access loosened because
    current Swift rejects the package's old SPI property-wrapper use.
  - `StepsConfig.xcconfig`, `StepsWidgetConfig.xcconfig`, and the widget
    target's hard-coded project bundle IDs were changed to
    `com.example.Steps` / `com.example.Steps.Widget`; command-line
    `PRODUCT_BUNDLE_IDENTIFIER` made both app and extension use the same ID and
    caused simulator install to fail.
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id com.example.Steps --inject --port 28815 --timeout 45`
- Evidence:
  - Initial report `/tmp/loupe-steps-ios-report-main` captured the real home
    screen. The screenshot showed the mountain art and current-step card, while
    compact/query output only exposed the tab bar labels. This is a SwiftUI
    semantic boundary, not a blank app.
  - `ui query --exact-text '목표들'` found tab ref `n61`. Same-snapshot
    `act tap --ref n61 --snapshot ... --backend auto` opened the goals screen.
    Trace `/tmp/loupe-steps-ios-trace-tab-goals` showed the navigation title
    `✅ 나의 목표`, segmented control, edit button, and list surface appearing;
    fresh report `/tmp/loupe-steps-ios-report-goals` confirmed the route.
  - The goals screen exposed useful UIKit bridge structure:
    `UISegmentedControl`, `UpdateCoalescingCollectionView`,
    `ListCollectionViewCell`, `UINavigationBar`, and tab bar refs. Audit found
    missing-testID on the segmented control plus an `AnimationView`
    `childOutsideParent` hint around the edit toolbar.
  - The visible `+ 목표 추가` SwiftUI button was not found by text query and
    live hit-test returned only the surrounding `HostingView`. A coordinate
    `act tap --x 206 --y 746` was still proven by trace
    `/tmp/loupe-steps-ios-trace-add-goal`: the bottom sheet and
    `UITextField text="새로운 목표..."` appeared. Fresh report
    `/tmp/loupe-steps-ios-report-add-goal-sheet` exposed the text field at
    `n125`.
  - Same-snapshot `act tap --ref n125` followed by
    `act type 'Loupe QA'` changed the text field. Trace
    `/tmp/loupe-steps-ios-trace-type-goal` and fresh report
    `/tmp/loupe-steps-ios-report-typed-goal` both showed
    `UITextField text="Loupe QA"`.
  - The visible `저장` SwiftUI button was also absent from text query and
    hit-test returned the sheet `HostingView`. A coordinate tap at `200,783`
    saved the row. Trace `/tmp/loupe-steps-ios-trace-save-goal` showed a
    `ListCollectionViewCell` appearing and the sheet moving offscreen; fresh
    screenshot `/tmp/loupe-steps-ios-report-after-save/screenshot.png` showed
    the persisted `Loupe QA` row.
  - The saved row text `Loupe QA` remained screenshot-only: `ui query
    --exact-text 'Loupe QA' --include-hidden` returned empty, and `snapshot.json`
    contained the `ListCollectionViewCell`/`CellHostingView` structure without
    the drawn SwiftUI `Text(goal.name)`. Use screenshot plus trace evidence for
    this kind of SwiftUI list row unless the app adds a stable accessibility
    identifier/probe.
  - `ui set --snapshot /tmp/loupe-steps-ios-report-after-save/snapshot.json
    --ref n39 alpha 0.45` changed the visible row alpha. Fresh report
    `/tmp/loupe-steps-ios-report-after-alpha` confirmed `uiKit.alpha` and
    `style.alpha` as `0.44999998807907104`. `ui reflect` correctly returned
    `sourceCandidates: []` for the SwiftUI-generated list cell.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same boundaries on port `28816`. Artifacts:
    `/tmp/loupe-steps-blind-command-log.txt`,
    `/tmp/loupe-steps-blind-report-main`,
    `/tmp/loupe-steps-blind-trace-tab-goals`,
    `/tmp/loupe-steps-blind-report-goals`,
    `/tmp/loupe-steps-blind-trace-add-goal`,
    `/tmp/loupe-steps-blind-report-add-goal-sheet`,
    `/tmp/loupe-steps-blind-trace-text-field-focus`,
    `/tmp/loupe-steps-blind-trace-type-goal`,
    `/tmp/loupe-steps-blind-report-typed-goal`,
    `/tmp/loupe-steps-blind-trace-save-goal`,
    `/tmp/loupe-steps-blind-report-after-save`,
    `/tmp/loupe-steps-blind-set-row-alpha.json`,
    `/tmp/loupe-steps-blind-report-after-alpha`, and
    `/tmp/loupe-steps-blind-reflect-row-alpha.json`. The blind run confirmed
    home-card text was screenshot-only, goals tab and text field were
    ref-queryable, add/save buttons needed coordinate traces, saved row text was
    screenshot-visible but absent from query/snapshot text, row alpha mutation
    worked, and reflect returned `sourceCandidates: []`.
- General fixes produced:
  - Skill guidance now calls out SwiftUI `List` rows created after persistence
    as a separate screenshot-visible/snapshot-absent text boundary.
  - Skill guidance now tells agents to treat screenshot-visible SwiftUI buttons
    inside hosting views as coordinate-action candidates only after hit-test,
    trace diff, and fresh screenshot/report proof.

### Expense Tracker

- Repo: https://github.com/abdorizak/Expense-Tracker-App
- Revision: `4dfa91809f9f9680c8d8c813b500ca1f8b996bb0`
- Platform: iOS UIKit
- UI: onboarding carousel, login form, secure password text field.
- Why it matters: a small real UIKit app is quick to rebuild and exposed two
  general runtime issues that toy examples missed.
- First verified scenario: iOS Simulator injection, onboarding Next/Get
  Started flow, login screen discovery, username/password typing.
- Build command:
  `xcodebuild -project 'Expense Tracker.xcodeproj' -scheme 'Expense Tracker' -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-expense-tracker CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.abdorizak.Expense-Tracker`
- Evidence from first pass:
  - `ui report`, `ui compact`, `ui tree --accessibility`, `ui tree --view`,
    `ui query`, `ui node`, `act tap`, `act type`, and
    `debug trace summary` worked against the injected app.
  - Paged onboarding trace diffs were noisy because offscreen carousel cells
    appear and disappear during page transitions. The reliable proof was a
    fresh compact observation plus visible text after each action, not the raw
    appeared/disappeared list alone.
  - After Get Started, screenshot showed the login screen but default compact,
    query, audit, and accessibility output still contained covered onboarding
    content. This produced a general surface-visibility fix for default
    discovery surfaces.
  - Secure password entry initially leaked the typed value through snapshots
    and action trace metadata. Secure fields now report redacted text, and
    `act type` trace records store `<redacted>` instead of the raw typed input.
  - Blind validation with only the Loupe skill and target contract reproduced
    the full onboarding and login flow on port `28932`. Reports:
    `/tmp/loupe-expense-tracker-blind-initial-DAveyg5I`,
    `/tmp/loupe-expense-tracker-blind-login-xkB3X96J`,
    `/tmp/loupe-expense-tracker-blind-after-username-gONBbrhE`,
    `/tmp/loupe-expense-tracker-blind-after-password-BonC9YsO`, and
    `/tmp/loupe-expense-tracker-blind-after-mutation-FG1W5GFV`; traces:
    `/tmp/loupe-expense-tracker-blind-trace-next1-NyK54cnh`,
    `/tmp/loupe-expense-tracker-blind-trace-next2-Sr8GXVEy`,
    `/tmp/loupe-expense-tracker-blind-trace-next3-r1aoISZy`,
    `/tmp/loupe-expense-tracker-blind-trace-getstarted-rsQbau3k`, and input
    traces under `/tmp/loupe-expense-tracker-blind-trace-*-*`. The blind run
    confirmed the onboarding route with fresh reports, typed username
    `loupe_user_01`, verified the password node's
    `uiKit.textField.isSecureTextEntry=true` plus redacted bullet text/value,
    confirmed exact dummy-password query returned `[]`, and changed the login
    heading to `Login QA` with a fresh mutation proof.
- General fixes produced:
  - Core default discovery excludes nodes fully covered by later visible
    surfaces while preserving hidden structural traversal for window/scene
    containers.
  - UIKit secure text fields expose `uiKit.textField.isSecureTextEntry` and
    redact text/value/accessibility value in snapshots.
  - CLI action traces redact typed input metadata before writing
    `action-before.json`, `action-target.json`, `action-after.json`, or failure
    traces.

### SwiggyClone

- Repo: https://github.com/dheerajghub/SwiggyClone
- Revision: `742a8bd7302a6d49555f64a45f98ac0cd9b1ee68`
- Platform: iOS UIKit
- UI: static food-delivery clone with compositional collection sections,
  orthogonal carousels, restaurant cells, a filter sheet, and detail screens.
- Why it matters: a real UIKit collection-view app exercises discovery,
  non-`UIControl` cell taps, compositional layout/self-sizing probes, visual
  mutation, and source reflection without API or account setup.
- Build command:
  `xcodebuild -project SwiggyClone.xcodeproj -scheme SwiggyClone -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-swiggyclone CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.dheerajdev.Swigggy`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id com.dheerajdev.Swigggy --inject --port 28760 --timeout 40`
- Evidence:
  - `ui report` captured a real injected UIKit snapshot at
    `/tmp/loupe-swiggyclone-ios-report-main`: `163` nodes, `31`
    accessibility nodes, `54` screen-map elements, `16` visible texts, `11`
    interactive elements, and three scroll views.
  - The view tree exposed the main `UICollectionView`, two
    `_UICollectionViewOrthogonalScrollView` sections, `FoodTopBannerCVCell`,
    `FoodCategoryCVCell`, `FoodFilterHeaderView`, and
    `RestaurantsListCVCell`. `ui query --text 'Sort/Filter'` found the filter
    control, and `ui node` on the restaurant cell showed the visible
    `Burger Point` semantic text and UIKit layout constraints.
  - `ui hit-test --point 354,486` hit the `Sort/Filter` button through
    `FoodFilterHeaderView -> UICollectionView -> FoodViewController`.
  - `act tap --backend runtime --ref n82` opened the filter sheet. Trace:
    `/tmp/loupe-swiggyclone-sort-filter-runtime-trace`. Fresh report:
    `/tmp/loupe-swiggyclone-ios-report-after-filter`, with `FilterView`,
    `APPLY`, `CLEAR ALL`, and sort/cuisine/offer rows visible.
  - Closing the sheet and recapturing restored the main feed. Trace:
    `/tmp/loupe-swiggyclone-filter-close-trace`; report:
    `/tmp/loupe-swiggyclone-ios-report-after-close`.
  - The top banner hit-test resolved to `FoodTopBannerCVCell`, which is a
    collection-view cell and not a runtime-activatable `UIControl`. The useful
    action path was `act tap --backend auto --ref n38`. Trace:
    `/tmp/loupe-swiggyclone-top-banner-auto-tap-trace`. Fresh detail report:
    `/tmp/loupe-swiggyclone-ios-report-detail`, verifying
    `Valentine's Special`, `9 RESTAURANTS`, and the detail collection view.
  - A self-sizing probe on a visible `RestaurantsListCVCell` returned
    `selfSizing=skipped:collection_layout_sizing_unknown`, which is the correct
    conservative result for this compositional layout instead of repeatedly
    forcing expensive invalidations.
  - Thin-command revalidation on port `28831` added real evidence for
    `debug scroll` and `act wait` without inventing a synthetic flow.
    `debug scroll --ref n14 --delta 0,600` wrote
    `/tmp/loupe-swiggyclone-thin-debug-scroll.json` with
    `beforeOffset=(0,0)` and `afterOffset=(0,600)` for the main
    `UICollectionView`. Fresh report
    `/tmp/loupe-swiggyclone-thin-after-debug-scroll` confirmed the same
    collection `contentOffset.y = 600`, removed `Burger Point` from default
    query, and made later restaurants such as `Sindhi Sweet` visible. Then
    `act wait value --ref n14 --key uiKit.scrollView.contentOffset.y --equals 600`
    wrote `/tmp/loupe-swiggyclone-thin-wait-scroll-offset.json`, and the
    post-help-fix rerun wrote
    `/tmp/loupe-swiggyclone-thin-wait-scroll-offset-truncated.json`, proving
    the predicate matched the live scroll container. The useful proof is the
    output plus fresh report/query/node evidence, not wait success alone.
  - Thin-command drag revalidation on port `28832` used the top banner
    orthogonal carousel instead of a synthetic drag target. Baseline report:
    `/tmp/loupe-swiggyclone-drag-main`; hit-test proof:
    `/tmp/loupe-swiggyclone-drag-hit-before.json`, where point `350,240`
    resolved through `FoodTopBannerCVCell -> _UICollectionViewOrthogonalScrollView`.
    `act drag --from 350,240 --to 80,240 --duration 0.7` wrote trace
    `/tmp/loupe-swiggyclone-drag-top-banner-trace`; the trace summary showed
    carousel `contentOffset` changing from `15,10` to `338.33,10`. Fresh report
    `/tmp/loupe-swiggyclone-drag-after` showed the settled offset `425,10`,
    children changing from two visible banner cells to four shifted cells, and
    `act wait value --ref n35 --key uiKit.scrollView.contentOffset.x --equals 425`
    wrote `/tmp/loupe-swiggyclone-drag-wait-carousel-offset-final.json`.
  - Fresh blind validation with the slim installed Loupe skill reproduced the
    same carousel proof on port `28843` with no repo edits. Artifacts:
    `/tmp/swiggy-carousel-20260605-170435-87365/before-report`,
    `/tmp/swiggy-carousel-20260605-170435-87365/hit-test-350-240.json`,
    `/tmp/swiggy-carousel-20260605-170435-87365/trace-drag`,
    `/tmp/swiggy-carousel-20260605-170435-87365/after-report`,
    `/tmp/swiggy-carousel-20260605-170435-87365/wait-offset-441.json`, and
    `/tmp/swiggy-carousel-20260605-170435-87365/carousel-drag-evidence.json`.
    The hit-test at `350,240` hit `FoodTopBannerCVCell n36`; its responder
    chain included `_UICollectionViewOrthogonalScrollView n35`. The trace
    summary showed offset `15,10 -> 342.33,10`, the fresh after report settled
    at `441,10`, and visible banner cell frames shifted to include
    `x=-171`, `x=69`, and `x=309`.
  - `ui set --ref n22 textColor --color '#ff3366'` changed the visible
    restaurant label. A fresh report at
    `/tmp/loupe-swiggyclone-ios-report-after-label-color` showed the UILabel
    `textColor` as red `1`, green `0.2`, blue `0.4`.
  - `ui reflect` on the mutation output now works without a test ID by using
    hierarchy hints. Artifact:
    `/tmp/loupe-swiggyclone-label-color-reflect-after-fallback.json`. It
    returned `RestaurantsListCVCell.swift` candidates, with
    `l.textColor = .black` as the top source hint.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same flow. It captured artifacts under
    `/tmp/loupe-swiggyclone-blind-validation-20260605T045644+0900`, verified
    the main feed collection/cell types, opened and closed the filter sheet,
    hit-tested the top banner as `FoodTopBannerCVCell`, used a native tap for
    the non-`UIControl` cell, verified the detail screen, changed the
    `Burger Point` label color, and reflected the mutation back to
    `RestaurantsListCVCell.swift:81`.
  - The blind agent also confirmed two guidance points: live `ui hit-test`
    should be run immediately after a fresh report, and raw UIKit `isVisible`
    can remain true for offscreen/dismissed nodes, so compact/query/surface
    evidence is a better proof of the current visible screen.
- General fixes produced:
  - Layout audit now uses surface-visible refs for duplicate test IDs,
    interactive target checks, contrast, and child containment. Dismissed or
    offscreen filter-sheet nodes no longer produce current-screen audit noise.
    Re-running the detail audit dropped the issue count from `34` to `10`,
    while the visible filter-sheet report still audits its visible controls.
  - `ui reflect` keeps exact testID source search first, then falls back to
    hierarchy-based source hints when no testID candidate exists. This makes
    ref-based UIKit cell mutations more useful while still treating the result
    as a hint, not a source patch.
  - Skill guidance now distinguishes runtime activation from native/auto taps
    for collection/table cells and documents conservative self-sizing skip
    reasons for compositional layouts.
  - `act wait` help now documents selector forms, `--key`, `--equals`,
    `--interval`, and `--output` so blind agents do not have to infer the
    predicate syntax. Wait summaries now truncate long container semantic text
    to keep collection-view offset waits readable.
  - Skill guidance now treats `debug scroll` as diagnostic scroll evidence that
    needs a named container, expected offset/content change, output path, and
    fresh after-proof. It also says `act wait` is synchronization evidence that
    still needs a fresh final-state artifact.
  - Skill guidance now treats `act drag` as proof only when the contract names
    the dragged surface, exact start/end coordinates or locator, trace dir,
    drag-specific postcondition, and fresh after-proof such as `contentOffset`,
    item/page visibility, value, or object-position change.
  - The blind validation prompt now clarifies that Loupe commands must use the
    grouped executable, while host setup or cleanup tools named in the contract
    are allowed. This avoids leaving launched simulator apps running merely
    because `loupe app` has no terminate command.

### IGListKit iOS

- Repo: https://github.com/Instagram/IGListKit
- Revision: `cc47ee42f759c255daa4c43b94c8f8ca2bfc09f4`
- Platform: iOS UIKit
- UI: collection-view example browser, IGListKit section controllers,
  flow-layout self-sizing cells, nib/manual/full-width cells, and list-driven
  navigation.
- Why it matters: a real open-source UIKit collection-view codebase exercises
  inactive label discovery inside tappable cells, native ref actions,
  delegate-owned sizing, visual mutation, and source reflection without account
  or network setup.
- Build command:
  `xcodebuild -quiet -project /tmp/loupe-open-source-candidates/IGListKit/Examples/Examples-iOS/IGListKitExamples.xcodeproj -scheme IGListKitExamples -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-iglistkit-ios -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64 clean build`
- Bundle ID: `com.instagram.IGListKitExamples`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --bundle-id com.instagram.IGListKitExamples --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --inject --port 28818 --timeout 30`
- Main-agent evidence:
  - Initial report `/tmp/loupe-iglistkit-ios-report-main` captured the real
    example menu: `128` view nodes, `31` accessibility nodes, `83`
    screen-map elements, `17` interactive elements, `14` visible texts, one
    scrollable collection view, and `13` audit issues.
  - `ui query --exact-text 'Self-sizing cells'` found the label at `n84`.
    `ui node --ref n84 --fields node,parent,children,siblings` showed that the
    UILabel itself was not interactive and the useful action target was its
    parent cell/container at `n82`.
  - `act tap --snapshot /tmp/loupe-iglistkit-ios-report-main/snapshot.json
    --ref n82 --backend auto` opened the self-sizing screen. Trace:
    `/tmp/loupe-iglistkit-ios-trace-open-self-sizing`. Fresh report:
    `/tmp/loupe-iglistkit-ios-report-self-sizing`.
  - The self-sizing report captured `207` view nodes, `58` accessibility
    nodes, `111` screen-map elements, `23` interactive elements, `34` visible
    texts, one scrollable collection view, and visible
    `ManuallySelfSizingCell`/`NibSelfSizingCell` content.
  - `ui node --ref n20 --fields node,parent` on the `Leverage agile` label
    showed a UILabel inside `ManuallySelfSizingCell`, with label constraints
    and parent cell frame `0,168,140,51`.
  - `ui mutations --host http://127.0.0.1:28818` exposed `textColor`,
    `fontSize`, `layout.hugging.vertical`, and related visual/layout mutation
    capabilities.
  - `ui set --snapshot ... --ref n20 textColor --color '#ff3366'
    --try-self-sizing --no-animate` changed the visible label color. Artifact:
    `/tmp/loupe-iglistkit-ios-set-textcolor-self-sizing.json`.
  - `ui set --snapshot ... --ref n20 fontSize 26 --try-self-sizing
    --no-animate` changed the font size from `17` to `26`. Artifact:
    `/tmp/loupe-iglistkit-ios-set-fontsize-self-sizing.json`.
  - Both mutation responses returned
    `selfSizing=skipped:delegate_size_for_item_owns_cell_size`. The probe
    context identified `containerTypeName=UICollectionView`,
    `cellTypeName=ManuallySelfSizingCell`,
    `selfSizingInvalidation=enabled`,
    `delegateRespondsToSizeForItemAt=true`, and
    `sizingOwner=delegateSizeForItem`; before/after cell frame and content
    size were unchanged. A fresh report
    `/tmp/loupe-iglistkit-ios-report-after-fontsize` confirmed the larger red
    label is clipped instead of resizing the cell. This is the correct bounded
    result for delegate-owned cell sizing.
  - `ui set --ref n20 layout.hugging.vertical 251 --try-self-sizing` returned
    `changed=false` with a warning that UIKit or the layout owner restored the
    effective value. Artifact:
    `/tmp/loupe-iglistkit-ios-set-hugging-self-sizing.json`.
  - `ui reflect` on the ref-based `textColor` and `fontSize` mutation outputs
    produced ranked source hints, but the candidates were still broad because
    the target label had no stable app-authored test ID. Useful app files can
    still be found by source terms such as `SelfSizingCellsViewController`,
    `SelfSizingSectionController`, and `ManuallySelfSizingCell`; treat the
    reflect output as a source-reading hint, not a patch target.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same flow. It captured artifacts under
    `/tmp/loupe-blind-iglistkit-ios-20260605T144355`, installed and launched
    the app on a fresh port, discovered `Self-sizing cells` as inactive label
    `n84`, used parent `n82` for the action, opened the self-sizing screen,
    mutated `Leverage agile` `fontSize` from `17` to `26`, and confirmed the
    label, cell, collection frame, and content size stayed unchanged with
    `selfSizingProbe.reason=delegate_size_for_item_owns_cell_size`.
    `ui reflect` again produced broad candidates rather than a tight source
    hit, which is the remaining rough edge for no-testID ref mutations here.
- General fixes produced:
  - CLI auto value inference now treats `fontSize`, `font.size`, and
    `style.fontSize` as scalar numeric mutation values instead of routing them
    through the generic CGSize parser because they end in `size`.

### Eureka iOS

- Repo: https://github.com/xmartlabs/Eureka
- Revision: `028ef8e3191a256b8f6b8bb6b9496efcb0762dbc`
- Platform: iOS UIKit
- UI: form-builder example app with `UITableView` rows, text fields, switches,
  sliders, steppers, segmented controls, navigation rows, XIB-backed custom
  cells, and input accessory views.
- Why it matters: a UIKit form/input-heavy app exercises table row discovery,
  inactive label-to-parent-cell actions, control-state traces, keyboard typing,
  visual mutation, and no-testID source reflection through table-cell
  hierarchy.
- Build command:
  `xcodebuild -quiet -project /private/tmp/loupe-open-source-candidates/Eureka/Example.xcodeproj -scheme Example -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-eureka-ios CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64 clean build`
- Bundle ID: `com.xmartlabs.Example`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --bundle-id com.xmartlabs.Example --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --inject --port 28821 --timeout 30`
- Main-agent evidence:
  - Initial report `/tmp/loupe-eureka-ios-report-main-v2` captured the real
    Examples menu: `145` view nodes, `42` accessibility nodes, `80`
    screen-map elements, `29` interactive elements, `13` visible texts, and one
    scrollable table.
  - `ui query --exact-text 'Rows'` returned inactive `UITableViewLabel` `n104`.
    `ui node --fields node,parent` showed the useful tap target was parent
    `UITableViewCellContentView` `n103`.
  - `act tap --snapshot ... --ref n103 --backend auto` opened the Rows screen.
    Trace: `/tmp/loupe-eureka-ios-trace-open-rows-v2`. Fresh report:
    `/tmp/loupe-eureka-ios-report-rows-v2`, with `293` nodes, `50`
    accessibility nodes, `106` screen-map elements, `34` visible texts, switch,
    slider, stepper, and segmented controls.
  - `ui query --role switch` found `UISwitch` `n196`. `ui node --ref n196`
    showed `uiKit.switchControl.isOn=true`. `act tap --ref n196` toggled it;
    trace `/tmp/loupe-eureka-ios-trace-toggle-switch` recorded
    `uiKit.switch.isOn:true->false`, and a fresh report confirmed
    `isOn=false`.
  - A `textColor` mutation on the `SwitchRow` label changed black to
    `#ff3366`. Artifacts:
    `/tmp/loupe-eureka-ios-set-switchrow-textcolor-v2.json` and
    `/tmp/loupe-eureka-ios-reflect-switchrow-textcolor-v2.json`.
  - Before the runtime fix, `ui reflect` returned `sourceCandidates: []` for
    that mutation because the target was a UIKit internal `UITableViewLabel`
    whose immediate parent was only `UITableViewCellContentView`. After the
    fix, mutation hierarchy includes ancestors such as `SwitchCell`, and
    reflect returns specific `SwitchCell.xib`, `SwitchRow.swift`, and
    `CustomDesignController.swift` candidates. XIB rows can still rank above
    Swift declarations, so candidates remain hints rather than patch targets.
  - Back navigation by button ref `n283` returned to the menu; opening
    `Native iOS Event Form` by parent row ref `n105` produced trace
    `/tmp/loupe-eureka-ios-trace-open-event-form` and report
    `/tmp/loupe-eureka-ios-report-event-form`.
  - The event form exposed `UITextField` refs for `Title`, `Location`, and
    `URL`. `act tap --ref n271` focused the Title field, showing keyboard and
    input accessory artifacts in `/tmp/loupe-eureka-ios-trace-focus-title`.
    `act type 'Loupe meetup'` changed the field; trace
    `/tmp/loupe-eureka-ios-trace-type-title` showed `UITextField` text
    `Title -> Loupe meetup`, and fresh report
    `/tmp/loupe-eureka-ios-report-after-title-type` made
    `ui query --exact-text 'Loupe meetup'` succeed.
- Blind-agent evidence:
  - A blind agent with only the repo Loupe skill and target contract reproduced
    launch on fresh port `28823`, main capture, inactive `Rows` label discovery,
    parent-cell tap, Rows capture, switch toggle, `SwitchRow` label mutation,
    useful `SwitchCell`/`SwitchRow`/XIB reflect candidates, back navigation,
    Native iOS Event Form navigation, Title focus, and typed
    `Loupe blind meetup`.
  - Artifacts:
    `/tmp/loupe-blind-eureka-ios-20260605-151508-main`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-trace-tap-rows`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-rows`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-trace-switch-toggle`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-rows-after-switch`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-switchrow-label-color-mutation.json`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-switchrow-label-color-reflect.json`,
    `/tmp/loupe-blind-eureka-ios-20260605-151508-native-form`, and
    `/tmp/loupe-blind-eureka-ios-20260605-151508-trace-type-title`.
  - The blind run stopped before the final post-type report. The main agent
    completed that verification with
    `/tmp/loupe-blind-eureka-ios-20260605-151508-native-form-after-type`, where
    `ui query --exact-text 'Loupe blind meetup'` returned text-field ref
    `n271`.
  - Blind rough edges found: requested port `28822` was already occupied by a
    different runtime, `app current` can be stale before a fresh launch/use
    updates selection, `app list --json --timeout 5` was too slow with many
    stale records, `ui compact <snapshot> --timeout` was advertised but rejected
    in snapshot mode, action commands need explicit `--udid` when multiple
    simulator platforms are booted, and failed/successful retries should not
    reuse the same trace directory.
- General fixes produced:
  - `LoupeMutationHierarchyContext` now carries optional ancestor summaries.
    UIKit/AppKit mutation responses populate the nearest ancestors, and
    `ui reflect` uses ancestor type/text terms for source ranking while keeping
    the immediate `parent` semantics intact.
  - `app list` now checks stored runtimes concurrently, so a large stale record
    set does not multiply the per-record timeout into a long apparent hang.
  - `ui compact <snapshot.json>` now accepts the runtime-selection options shown
    in help, including `--timeout`, even when compacting an offline snapshot.
  - Skill guidance now explains table/collection-cell leaf mutations where the
    target is a UIKit internal label/control but the useful source hint is an
    app-owned ancestor cell.
  - Skill guidance now calls out printed-host usage after launch, explicit
    `--udid` when several simulators are booted, fresh trace directories per
    retry, and fresh-port recovery from port collisions.

### MessageKit iOS

- Repo: https://github.com/MessageKit/MessageKit
- Revision: `b4493fe468c82f87cd2a533d1abe63d9b698d2b8`
- Platform: iOS UIKit
- UI: chat example app with a launcher table, `MessagesCollectionView`,
  reusable message cells, `InputBarAccessoryView`, text entry, send button
  state, and MessageKit source reflection.
- Why it matters: a real UIKit chat/list example exercises dynamic collection
  cell reuse, input accessory views whose text view can be surface-occluded by
  UIKit internals, keyboard typing, transient send state, visual mutation, and
  source reflection into a library cell.
- Build command:
  `xcodebuild -quiet -project /private/tmp/loupe-open-source-candidates/MessageKit/Example/ChatExample.xcodeproj -scheme ChatExample -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-messagekit-ios CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64 clean build`
- Bundle ID: `com.messagekit.ChatExample`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --bundle-id com.messagekit.ChatExample --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --inject --port 28824 --timeout 30`
- Main-agent evidence:
  - Initial report `/tmp/loupe-messagekit-ios-report-main` captured the real
    launcher: `140` nodes, `41` accessibility nodes, `75` screen-map elements,
    `29` interactive elements, and visible example rows such as
    `Basic Example`, `Advanced Example`, and `SwiftUI Example`.
  - `Basic Example` was an inactive label; `ui node --fields node,parent`
    showed parent `UITableViewCellContentView` `n98` as the useful tap target.
    `act tap --snapshot ... --ref n98 --backend auto` opened the chat screen.
    Trace: `/tmp/loupe-messagekit-ios-trace-open-basic`.
  - Chat report `/tmp/loupe-messagekit-ios-report-basic` captured
    `MessagesCollectionView`, `TextMessageCell`, `MessageLabel`,
    `InputBarAccessoryView`, `InputTextView`, and disabled
    `InputBarSendButton`. The input text view existed in the snapshot as
    `role=textView`, but default role query missed it until `--include-hidden`
    because UIKit text-layout child views covered the surface samples. A live
    `ui hit-test --point 170,815` still resolved the responder chain through
    `InputTextView`.
  - Ref tap on the text view failed with
    `No Loupe accessibility or view node matched selector`, but coordinate tap
    at the verified input point focused it. Trace:
    `/tmp/loupe-messagekit-ios-trace-focus-input-coordinate`, showing keyboard
    placeholder and text-selection views.
  - `act type 'Loupe chat ping 0605'` changed `InputTextView` text and changed
    `InputBarSendButton` from disabled to enabled. Trace:
    `/tmp/loupe-messagekit-ios-trace-type-message`. Fresh report
    `/tmp/loupe-messagekit-ios-report-after-type` confirmed the text and
    enabled Send ref.
  - `act tap --snapshot ... --ref n189` sent the message. The immediate trace
    `/tmp/loupe-messagekit-ios-trace-send-message` saw the transient
    `Sending...` state, and a later report
    `/tmp/loupe-messagekit-ios-report-after-send` confirmed the sent
    `MessageLabel` text `Loupe chat ping 0605` and Send disabled again.
  - MessageKit demo data can regenerate or shift between captures. Text/ref
    mutation against message cells is therefore unstable unless the ref comes
    from a fresh live query and is used immediately. A successful ref mutation
    at `/tmp/loupe-messagekit-ios-final-set-message-ref-textcolor.json`
    changed a visible `MessageLabel` `textColor` from black to `#ff3366`.
  - `ui reflect` on that mutation wrote
    `/tmp/loupe-messagekit-ios-final-reflect-message-textcolor.json` and
    returned a useful top candidate:
    `Sources/Views/Cells/TextMessageCell.swift:85`
    (`messageLabel.textColor = textColor`), with related `messageLabel`
    configuration lines nearby.
- Blind-agent evidence:
  - A blind agent with only the Loupe skill and target contract reproduced the
    same flow on port `28827`: launch/current runtime verification, main
    report, Basic Example navigation, chat report, input coordinate focus,
    typed `Loupe blind chat ping`, enabled Send, Send tap, and fresh reports
    showing the transient `Sending...` state followed by cleared input and
    disabled Send.
  - Artifacts:
    `/tmp/loupe-blind-messagekit-ios-main`,
    `/tmp/loupe-blind-messagekit-ios-chat`,
    `/tmp/loupe-blind-messagekit-ios-after-coordinate-type`,
    `/tmp/loupe-blind-messagekit-ios-after-send`,
    `/tmp/loupe-blind-messagekit-ios-after-send-late`,
    `/tmp/loupe-blind-messagekit-ios-after-mutation`, and traces under
    `/tmp/loupe-blind-messagekit-ios-traces`.
  - The blind run independently found the same rough edges: `InputTextView`
    ref tap failed while coordinate focus worked, `act type` needs fresh value
    verification because trace output alone can be misleading, and MessageKit
    demo data/view reuse makes sent message text and message-cell refs drift
    quickly.
  - The blind agent found one additional general CLI gap: `ui set-many` worked
    well for visible `MessageLabel` color changes, but `ui reflect` could not
    consume the set-many summary. A follow-up main-agent rerun at
    `/tmp/loupe-messagekit-ios-set-many-reflect-fix` verified the fix:
    `set-many matched=7 mutations=7 verified=7 accuracy=1`, summary now points
    to `responses.json`, and `ui reflect summary.json` wrote 7 reflections with
    `TextMessageCell.swift:85` as the top source hint.
- General fixes produced:
  - `ui set` now carries an opt-in `--include-hidden` flag through the mutation
    request model for cases where the target is intentionally offscreen or
    surface-occluded.
  - `LoupeSnapshotQuery` now ranks visible matches ahead of hidden/offscreen
    matches even when `includeHidden` is enabled, so dynamic list/cell
    mutations are less likely to select an offscreen duplicate before a visible
    one.
  - `ui set-many` now writes per-target mutation responses to
    `responses.json`, and `ui reflect` accepts a set-many summary or response
    array in addition to a single mutation response.
  - Skill guidance now calls out input accessory text views that may need
    `--include-hidden` for discovery, and dynamic reused cells where the
    mutation response target frame/visibility must be checked.

### UpcomingMovies

- Repo: https://github.com/DeluxeAlonso/UpcomingMovies
- Revision: `d07c8853630c853d4d4cb8f3defb783bb664e48a`
- Platform: iOS UIKit
- UI: CocoaPods-based TMDb movie app with tab navigation, UIKit navigation
  bars, search controller/search bar, table views, empty/error states, widget
  extension, and app-group-backed local storage.
- Why it matters: a realistic UIKit app with external setup friction exercises
  injection against a non-toy storyboard app, tab movement, search-field focus
  and typing, live hit-test/responder-chain evidence, mutation, and source
  reflection where parent type names can be substrings of unrelated types.
- Build setup:
  `bundle _2.2.13_ install --path vendor/bundle && bundle _2.2.13_ exec pod install`
- Build command:
  `xcodebuild -workspace UpcomingMovies.xcworkspace -scheme UpcomingMovies -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-upcomingmovies-ios CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.Alonso.UpcomingMovies.AppDev`
- External-only automation patches:
  - Skipped the SwiftLint build phase because bundled SwiftLint 0.41 crashes
    against the local Xcode SourceKit runtime.
  - Added an unsigned-simulator fallback from the app group container to
    Application Support so CoreData initialization does not `fatalError` when
    app group entitlements are unavailable.
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id com.Alonso.UpcomingMovies.AppDev --inject --port 28772 --timeout 45`
- Evidence:
  - The first injected launch proved Loupe injection worked before the app
    crashed: simulator logs contained
    `LoupeInjector started on 127.0.0.1:28772`, then the app died on the
    missing app-group entitlement. Treat this as app setup evidence, not a
    Loupe injection failure.
  - After the external-only fallback, `ui report` captured the real app at
    `/tmp/loupe-upcomingmovies-ios-report-wait`. The app settled on a
    network-error state with `Upcoming movies`, `¡Ups!`, `Retry`, and three
    tab items.
  - `act tap --backend auto --ref n95` moved from `Upcoming` to `Search`.
    Trace: `/tmp/loupe-upcomingmovies-ios-trace-tap-search`. Fresh report:
    `/tmp/loupe-upcomingmovies-ios-report-search`, with
    `UISearchBarTextField`, `UITableView`, `Upcoming`, `Search`, and `Account`
    visible.
  - Tapping the search field and running `act type matrix` produced trace
    artifacts at `/tmp/loupe-upcomingmovies-ios-trace-focus-search` and
    `/tmp/loupe-upcomingmovies-ios-trace-type-matrix`. Fresh report:
    `/tmp/loupe-upcomingmovies-ios-report-typed`, where the search field text
    is `Matrix` and the screen shows `Recent searches`.
  - `ui tree --accessibility` on the typed report exposed the table, search
    field, clear/cancel buttons, nav title, and tab buttons. `ui tree --view`
    exposed the underlying `UISearchBar`, `UISearchBarTextField`,
    `_UISearchBarFieldEditor`, `HeaderView`, and tab bar internals.
  - `ui hit-test --point 120,140` wrote
    `/tmp/loupe-upcomingmovies-ios-hit-searchfield.json`, resolving the point
    to `UISearchBarTextField` with responder chain through
    `_UISearchBarSearchContainerView`, `UISearchBar`, `UINavigationBar`,
    `MainTabBarController`, `UIWindow`, and `AppDelegate`.
  - `ui audit` on the typed report found one useful issue: a visible search
    cancel `UIButton` without a test ID.
  - `ui set --ref n52 textColor --color '#ff3366'` changed the `Recent
    searches` label. Fresh report `/tmp/loupe-upcomingmovies-ios-report-color`
    confirmed the UILabel `textColor` as red `1`, green `0.2`, blue `0.4`.
  - A blind agent with only the repo Loupe skill and target contract reproduced
    the same loop from the already-running host. It cleared the existing
    `Matrix` search text, typed `blade` and verified the app-capitalized
    `Blade` value in a fresh report, hit-tested the search field, changed
    `Recent searches` to `#33aa66`, verified the fresh color state, and
    reflected the mutation. Artifacts:
    `/tmp/loupe-upcomingmovies-blind-report-start`,
    `/tmp/loupe-upcomingmovies-blind-report-typed`,
    `/tmp/loupe-upcomingmovies-blind-report-mutated`,
    `/tmp/loupe-upcomingmovies-blind-hit-test-search-field.json`,
    `/tmp/loupe-upcomingmovies-blind-set-recent-textcolor.json`, and
    `/tmp/loupe-upcomingmovies-blind-reflect-recent-textcolor.json`.
  - The blind audit found two useful current-screen issues on the typed Search
    state: a missing test ID on the visible search cancel `UIButton`, and low
    contrast on the original `Recent searches` label (`3.18 < 4.5`).
  - Initial `ui reflect` ranked unrelated `CustomListDetailHeaderView`
    `textColor` lines above the real `HeaderView` parent. This produced a
    general ranking fix: exact hierarchy type filename/declaration matches now
    outrank substring property matches. Re-running reflect wrote
    `/tmp/loupe-upcomingmovies-ios-reflect-recent-color-fixed.json`, with
    `HeaderView.swift` as the top source hint.
- General fixes produced:
  - `ui reflect` now gives stronger weight to exact hierarchy type file names
    and declarations before substring matches such as
    `CustomListDetailHeaderView` containing `HeaderView`.
  - README, plan, and skill mutation examples no longer pass `--test-id` to
    `ui mutations`, because that command lists live mutation capabilities and
    does not take a selector.

### SwiftTerm MacTerminal

- Repo: https://github.com/migueldeicaza/SwiftTerm
- Revision: `899146260232c3eb67802975427ac5e115996918`
- Platform: macOS AppKit
- UI: document-based terminal window with a custom `LocalProcessTerminalView`.
- Why it matters: a real AppKit app exposed macOS launch lifecycle, non-
  simulator report artifacts, and custom-rendered view action boundaries.
- Build command:
  `xcodebuild -project TerminalApp/MacTerminal.xcodeproj -scheme MacTerminal -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-swiftterm-mac CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `org.tirania.MacTerminal`
- External-only automation patches:
  - Added `/tmp/loupe-open-source-candidates/SwiftTerm/Sources/SwiftTerm/SyncDebug.swift`
    with a no-op `SyncDebug.log` because the checked-out revision referenced a
    missing helper.
  - Added a launch-time `NSDocumentController.shared.newDocument(nil)` call in
    the candidate app's `AppDelegate` so direct validation opens a document
    window.
- Working launch command:
  `open -n -F --env LOUPE_PORT=28749 --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-swiftterm-mac/Build/Products/Debug/MacTerminal.app`
- Evidence:
  - Direct executable launch could return `/health` and then exit before
    `/snapshot`; LaunchServices `open --env` kept the document app alive.
  - `ui report --host http://127.0.0.1:28749` captured a real AppKit snapshot.
    Artifacts: `/tmp/loupe-swiftterm-report-after-summary-fix`.
  - `ui compact` reported one interactive `LocalProcessTerminalView` with
    frame `249,226,800,600`.
  - `ui tree --view --depth 6` and `ui tree --accessibility --depth 6` exposed
    `NSWindow`, `NSView`, `LocalProcessTerminalView`, `NSScroller`, and
    `CaretView`.
  - `ui audit` returned zero issues.
  - `ui hit-test --point 291,242` hit `LocalProcessTerminalView` and returned
    an AppKit responder chain through `NSView`, `ViewController`, `NSWindow`,
    and `NSWindowController`.
  - `act tap --backend runtime --ref n4` produced a trace but failed with
    `unsupported_activation_target`: the matched `LocalProcessTerminalView` is
    not an `NSControl`. Artifacts:
    `/tmp/loupe-swiftterm-trace-runtime-tap`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result. It launched through `open --env`, verified `app current`
    as live, captured `/tmp/loupe-swiftterm-report-20260605-0302`, hit-tested
    `LocalProcessTerminalView` at `650,526`, and confirmed
    `act tap --backend runtime --ref n4` fails with
    `unsupported_activation_target` instead of being claimed as a success.
    Artifacts: `/tmp/loupe-swiftterm-hit-test-650-526.json`,
    `/tmp/loupe-swiftterm-tap-n4-trace`.
- General fixes produced:
  - `ui report` no longer writes a stale simulator screenshot for non-
    simulator runtimes. The screenshot artifact is optional and the report
    summary now tells agents to use screen-map/audit/accessibility artifacts
    when no screenshot is available.
  - `act tap` help now exposes `--backend native|runtime|auto`, and action help
    no longer implies `--udid` is mandatory for every runtime path.
  - The skill documents macOS `open --env` launch, the `/health` vs `/snapshot`
    lifecycle check, optional report screenshots, and runtime tap limits for
    custom AppKit views.

### CotEditor

- Repo: https://github.com/coteditor/CotEditor
- Revision: `1bbc15c2fabc170931d5963798ae87463991d3db` (`6.2.6`)
- Platform: macOS AppKit
- UI: document-based text editor with `NSTextView` subclass, split views,
  status bar controls, AppKit/SwiftUI bridge controls, and localized labels.
- Why it matters: a real editor validates macOS document launch, AppKit text
  view semantics, hit-test/responder-chain depth, mutation against an
  `NSTextView` subclass, and source reflection when the test ID is also a type
  name.
- Build note:
  - Current `main` and `7.0.4` use Xcode project object version `100`, which
    this local Xcode cannot open. Tag `6.2.6` uses object version `90` and
    builds successfully.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/CotEditor/CotEditor.xcodeproj -scheme CotEditor -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-coteditor-mac -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO ENABLE_HARDENED_RUNTIME=NO build`
- Bundle ID: `com.coteditor.CotEditor`
- Working launch command:
  `open -n -F --env LOUPE_PORT=28785 --env LOUPE_BIND_HOST=127.0.0.1 --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib -a /tmp/loupe-build-coteditor-mac/Build/Products/Debug/CotEditor.app /tmp/loupe-coteditor-sample.txt`
- Evidence:
  - `app info --host http://127.0.0.1:28785` identified the runtime as
    `com.coteditor.CotEditor` on macOS.
  - `ui report --host http://127.0.0.1:28785` captured
    `/tmp/loupe-coteditor-mac-report-main`: `101` view nodes,
    `19` accessibility nodes, `38` screen-map elements, `9` visible texts,
    `6` interactive elements, and one `EditorScrollView`.
  - Non-simulator screenshot output was unavailable, so the useful artifacts
    were `snapshot.json`, `compact.json`, `screen-map.json`,
    `accessibility.json`, and `audit.json`.
  - `ui compact`, `ui screen`, `ui tree --view --depth 18`, and
    `ui tree --accessibility --depth 8` exposed `BidiScrollView` with
    `testID=EditorScrollView` and `EditorTextView` with
    `testID=EditorTextView`, first-responder/focused state, and document text
    `Loupe CotEditor sample`.
  - `ui hit-test --point 976,519` and
    `ui responder-chain --test-id EditorTextView` resolved the editor leaf and
    returned the chain
    `EditorTextView -> NSClipView -> BidiScrollView -> NSStackView ->
    EditorTextViewController -> EditorViewController -> DocumentWindow`.
  - `act tap --backend auto --test-id EditorTextView` resolved the correct
    editor target but did not prove a click. The main run saw `/activate`
    timeouts and a poisoned runtime on `EditorTextView` and a same-snapshot
    `LF` popup ref; the blind run returned the cleaner boundary
    `unsupported_activation_target` with
    `Matched view EditorTextView is not an NSControl.` Treat both as macOS
    activation limits, preserve the trace, and relaunch before continuing a
    mutation scenario if the runtime starts timing out.
  - Relaunching on port `28786`, `ui set --test-id EditorTextView alpha 0.52`
    changed the real editor view. A fresh report at
    `/tmp/loupe-coteditor-mac-report-after-alpha` confirmed both
    `style.alpha` and `uiKit.alpha` as `0.52`.
  - Initial `ui reflect` ranked broad `EditorTextView` selector references
    before the useful source line. After the ranking fix, reflect writes
    `/tmp/loupe-coteditor-mac-reflect-alpha-ranked.json`, with
    `EditorTextView.swift:183 self.identifier =
    NSUserInterfaceItemIdentifier("EditorTextView")` first and
    `EditorTextViewController.swift:97 let textView = EditorTextView(` also
    included.
  - Blind validation with only the Loupe skill and target contract reproduced
    the useful AppKit evidence on ports `28787` and `28788`. Artifacts:
    `/tmp/loupe-coteditor-blind-report-main`,
    `/tmp/loupe-coteditor-blind-hit-test-center.json`,
    `/tmp/loupe-coteditor-blind-responder-chain-editor.json`,
    `/tmp/loupe-coteditor-blind-trace-tap-editor`,
    `/tmp/loupe-coteditor-blind-report-mutation-before`,
    `/tmp/loupe-coteditor-blind-set-editor-alpha.json`,
    `/tmp/loupe-coteditor-blind-report-after-alpha`, and
    `/tmp/loupe-coteditor-blind-reflect-alpha.json`. It confirmed
    `EditorTextView` focus/first-responder state, the expected responder chain,
    clean `unsupported_activation_target` for runtime tap, fresh alpha
    `0.47`, preserved document text, and the same top reflect candidate at
    `EditorTextView.swift:183`.
- General fixes produced:
  - `ui reflect` now ranks testID matches by source usefulness instead of path
    order. Exact identifier assignments, type declarations, and construction
    lines outrank menu `#selector` or notification references when a test ID is
    also an app type name.
  - A regression test covers the CotEditor-shaped AppKit case so future
    ranking changes do not put selector references above the actual view
    declaration/identifier setup.

### Equinox

- Repo: https://github.com/rlxone/Equinox
- Revision: `d776eb22bedf4951cac824251a41868035359c13`
- Platform: macOS AppKit
- UI: localized dynamic-wallpaper app with a welcome window, custom AppKit
  content views, image/text type-selection rows, and a GitHub button.
- Why it matters: a real AppKit app with custom framework views exercises
  localized static text, custom row hit-testing, accessibility activation that
  can report success without visible route change, audit triage, visual
  mutation, and source reflection.
- Build command:
  `xcodebuild -workspace Equinox.xcworkspace -scheme Equinox -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-equinox-mac CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.rlxone.equinox`
- Working launch command:
  `open -n -F --env LOUPE_PORT=28762 --env LOUPE_BIND_HOST=127.0.0.1 --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-equinox-mac/Build/Products/Debug/Equinox.app`
- Evidence:
  - The app built without source edits. The workspace fetched one Swift package,
    `SolarNOAA` at `1.0.0`.
  - `ui report --host http://127.0.0.1:28762` captured a real AppKit snapshot
    at `/tmp/loupe-equinox-mac-report-main-after-audit-fix`: `49` view nodes,
    `16` accessibility nodes, `44` screen-map elements, `15` visible texts,
    five interactive elements, and no simulator screenshot, which is expected
    for a non-simulator macOS runtime.
  - `ui compact`, `ui tree --view`, and `ui tree --accessibility` exposed
    localized text and custom AppKit classes: `WelcomeContentView`, `TypeView`,
    `TypeItemView`, `StyledLabel`, `ImageView`, and `ContainerButton`. Visible
    text included `Equinox에 오신 것을 환영합니다.`, `유형 선택`, `태양`, `시간`,
    `화면 모드`, and `Github`.
  - `ui hit-test --point 1180,307` hit the `태양` row label, while
    `ui hit-test --point 1022,303` hit the `Solar` image. Both responder chains
    included the containing `TypeItemView`, which is the useful source context
    even when the leaf hit is not the row view itself.
  - `act tap --backend runtime --ref n25` on the `Solar` image wrote
    `activation_applied` in `/tmp/loupe-equinox-solar-runtime-tap-trace`, but
    the trace diff had no appeared/changed/disappeared nodes and a fresh report
    showed no route change. Treat this as unproven UI action success; AppKit
    activation logs alone are not enough evidence.
  - `ui set --ref n27 textColor --color '#ff3366'` changed the visible `태양`
    `StyledLabel`. A fresh report at
    `/tmp/loupe-equinox-mac-report-after-label-color` showed `textColor` red
    `1`, green `0.2`, blue `0.4`.
  - `ui reflect` on the mutation output returned useful no-testID candidates:
    `TypeItemView.swift` lines setting `titleLabel.textColor` and
    `descriptionLabel.textColor`, plus `StyledLabel.swift` where
    `textColor = style?.color` is applied. Artifact:
    `/tmp/loupe-equinox-solar-label-color-reflect.json`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result under
    `/tmp/loupe-equinox-blind-validation-20260605-051505`. It verified the
    localized welcome/type-selection screen, confirmed row hit-tests land on
    `StyledLabel`/`ImageView` leaves with `TypeItemView` in the responder
    chain, treated the `activation_applied` tap as unproven because trace and
    fresh report diffs were empty, mutated the `태양` label color, and reflected
    to `TypeItemView.swift` plus `StyledLabel.swift`.
  - The blind agent also found that `app current` can be stale when validating
    a manually launched macOS host runtime; `app info --host
    http://127.0.0.1:28762` was the authoritative live-runtime identity check.
- General fixes produced:
  - Layout audit now ignores passive `*ImageView` accessibility image elements
    with no test ID, no gestures, and no control events for small-target checks.
    Re-running the Equinox audit dropped from four issues to one remaining
    `ContainerButton` small-target issue.
  - Skill guidance now distinguishes `activation_applied` from proven visible
    state change on AppKit runtimes.

### Loop

- Repo: https://github.com/mrkai77/Loop
- Revision: `d7f9a1a7dff958e16c5421dd8c30164039192367`
- Platform: macOS SwiftUI with AppKit/Luminare host views
- UI: menu-bar window manager settings window, radial-menu preview, inspector
  pane, update window, switches, scroll panes, and Accessibility permission
  setup.
- Why it matters: a real SwiftUI macOS app exposed launch-time permission
  modal blocking, sparse accessibility semantics, AppKit-backed SwiftUI switch
  activation, visual mutations, and SwiftUI hosting generic source reflection.
- Build command:
  `xcodebuild -project Loop.xcodeproj -scheme Loop -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-loop-mac -skipMacroValidation CODE_SIGNING_ALLOWED=NO ENABLE_HARDENED_RUNTIME=NO build`
- Bundle ID: `com.MrKai77.Loop`
- External-only automation patch:
  - Added `LOUPE_SKIP_ACCESSIBILITY_PROMPT=1` handling around
    `AccessibilityManager.requestAccess()` in the candidate app so validation
    can bypass the launch-time `NSAlert.runModal()` permission prompt.
- Working launch command:
  `open -n -F --env LOUPE_PORT=28779 --env LOUPE_BIND_HOST=127.0.0.1 --env LOUPE_SKIP_ACCESSIBILITY_PROMPT=1 --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-loop-mac/Build/Products/Debug/Loop.app`
- Evidence:
  - Without the external bypass, Loupe injection started and `/health`
    responded, but `ui report` timed out. A process sample at
    `/tmp/loupe-loop-sample.txt` showed the main thread blocked in
    `AccessibilityManager.requestAccess()` -> `NSAlert.runModal`, while the
    Loupe server thread waited in `accept`.
  - With the bypass, `app info --host http://127.0.0.1:28779` identified the
    live macOS runtime and `ui report` captured
    `/tmp/loupe-loop-mac-report-main`: `131` view nodes, `12` accessibility
    nodes, `117` screen-map elements, `8` visible texts, `8` interactive
    elements, and no simulator screenshot, which is expected for this macOS
    runtime.
  - `ui tree --view` exposed `NSStatusBarButton`,
    `LuminareWindowHostingView<...SettingsContentView...>`,
    `HostingScrollView`, `PlatformSwitch`, the settings window, and an update
    window. `ui tree --accessibility` was much sparser and mainly exposed
    buttons, scroll views, and switch values.
  - `act tap --backend auto --ref n67 --host http://127.0.0.1:28779` activated
    a SwiftUI-backed `PlatformSwitch`. Trace:
    `/tmp/loupe-loop-mac-trace-tap-switch`; summary showed the switch value at
    the same frame changing from `0` to `1`.
  - `ui set --ref n74 alpha 0.35` changed another `PlatformSwitch`. A fresh
    report and `ui node` confirmed `style.alpha` and `uiKit.alpha` as `0.35`.
  - Reflecting the switch mutation returned `sourceCandidates: []`, which is a
    valid bounded result for SwiftUI-created bridge controls such as
    `PlatformSwitch`.
  - Mutating the settings hosting view `n10` to alpha `0.92` worked. Before the
    generic type parsing fix, `ui reflect` returned no candidates even though
    the type name contained `SettingsContentView`. After the fix, reflect wrote
    `/tmp/loupe-loop-mac-reflect-settings-alpha-after-generic-fix.json`, with
    `SettingsContentView.swift:12` and `SettingsWindowManager.swift:82` as
    ranked source hints.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same loop under
    `/tmp/loupe-loop-blind-validation-20260604T232918Z`. It verified the live
    host identity, captured the same sparse-accessibility/rich-view-tree
    settings window, toggled `PlatformSwitch` `n67` with a trace diff plus
    fresh report proof, changed `n74` alpha to `0.35`, changed the
    `SettingsContentView` hosting view `n10` alpha to `0.92`, and reflected the
    mutation back to `SettingsContentView.swift:12`.
  - The blind agent also kept the evidence bounded: macOS screenshots were
    unavailable for this runtime, switch accessibility labels were sparse
    `0`/`1` values, and reflect output was treated as source candidates only.
- General fixes produced:
  - `ui reflect` now extracts identifier terms from generic SwiftUI/AppKit
    hosting type names such as
    `LuminareWindowHostingView<...SettingsContentView...>`, so app content
    view types can become ranked source candidates.
  - Skill guidance now covers macOS apps that serve `/health` while
    launch-time Accessibility/Input Monitoring permission modals block
    snapshot generation.

### Yattee macOS

- Repo: https://github.com/yattee/yattee
- Revision: `c0815353d7c8025a376c855159d64eefe16a7a2b`
- Platform: macOS SwiftUI/AppKit
- UI: video client main window with SwiftUI navigation split view, sidebar
  outline list, AppKit hosting views, player surfaces, and media/network
  dependencies.
- Why it matters: a real multiplatform SwiftUI app replaces the currently
  blocked Gifski slot with a buildable macOS SwiftUI target. It exposes sparse
  semantic text, rich AppKit/SwiftUI bridge structure, testID-backed internal
  views, list-row activation limits, visual mutation, and broad source
  reflection hints.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/yattee/Yattee.xcodeproj -scheme 'Yattee (macOS)' -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-yattee-mac -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO ENABLE_HARDENED_RUNTIME=NO build`
- Bundle ID: `stream.yattee.app`
- Working launch command:
  `open -n -F --stdout /tmp/loupe-yattee-open.stdout.log --stderr /tmp/loupe-yattee-open.stderr.log --env LOUPE_PORT=28844 --env LOUPE_BIND_HOST=127.0.0.1 --env CFFIXED_USER_HOME=/tmp/loupe-yattee-home --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-yattee-mac/Build/Products/Debug/Yattee.app`
- Evidence:
  - `xcodebuild -list` resolved `Yattee (macOS)` successfully, unlike the
    Gifski project-file compatibility failure. The build succeeded under
    `/tmp/loupe-build-yattee-mac`.
  - `app info --host http://127.0.0.1:28844` identified a live macOS runtime
    for `stream.yattee.app`, PID `1053`.
  - `ui report --host http://127.0.0.1:28844` captured
    `/tmp/loupe-yattee-mac-report-main`: `86` view nodes, `10`
    accessibility nodes, `45` screen-map elements, `2` interactive elements,
    one scroll view, and no screenshot, which is expected for this macOS host
    runtime.
  - `ui compact` and `ui screen` showed `visibleTexts: []`, but the view tree
    exposed `NSWindow`, `AppKitWindowHostingView<ModifiedContent<AnyView,
    RootModifier>>`, `NSSplitView`, `SwiftUIOutlineListView`,
    `ListTableRowView`, `ListTableCellView`, and test IDs such as
    `shapeView`, `lighteningView`, `ListRow`, and `ListCell`. This is a useful
    SwiftUI semantic boundary, not a blank app.
  - `ui node --test-id shapeView` found an `NSView` at frame
    `340,209,336,64` with `style.alpha=1` and `uiKit.alpha=1`. Live
    `ui hit-test --point 508,241` landed on `SwiftUIOutlineListView`, showing
    that the app-visible point is covered by the list surface even though
    `shapeView` is queryable by test ID.
  - `ui set --test-id shapeView alpha 0.42 --no-animate` wrote
    `/tmp/loupe-yattee-mac-shape-alpha.json`. Fresh report
    `/tmp/loupe-yattee-mac-report-after-alpha` and `ui node` confirmed
    `style.alpha` and `uiKit.alpha` as `0.41999999999999998`.
  - `ui reflect /tmp/loupe-yattee-mac-shape-alpha.json --source
    /tmp/loupe-open-source-candidates/yattee` wrote
    `/tmp/loupe-yattee-mac-shape-alpha-reflect.json`. It returned non-empty
    but broad candidates, with `VerticalScrollingFix.swift` and unrelated
    SwiftUI/player files near the top; treat these as weak source hints rather
    than patch instructions.
  - `act tap --snapshot /tmp/loupe-yattee-mac-report-main/snapshot.json
    --ref n56 --backend auto` failed with
    `unsupported_activation_target` because `ListTableRowView` is not an
    `NSControl`. Fresh hit-test at `508,316` showed the point handled by
    `SwiftUIOutlineListView` with responder-chain evidence through
    `ListCoreScrollView`, `AppKitPlatformViewHost`, `NSSplitView`, and
    `AppKitWindow`. This is a bounded AppKit/SwiftUI list-row activation gap,
    not a route success.
  - Blind validation with only the slim Loupe skill and target contract
    reproduced the same result on port `28858`. Artifacts:
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/app-info.json`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/report-initial`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/mutation-shapeView-alpha.json`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/report-after-alpha`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/reflect-shapeView-alpha.json`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/hit-test-listrow-508-316.json`,
    `/tmp/loupe-yattee-blind-20260605-171714-p28858/responder-chain-listrow-n56.json`,
    and `/tmp/loupe-yattee-blind-20260605-171714-p28858/trace-tap-listrow-n56`.
    It verified `visibleTexts: 0` with useful view/testID structure, proved
    `shapeView` alpha `1 -> 0.42` with a fresh report, classified reflect
    candidates as broad/weak, preserved the row activation error, and
    terminated the launched app.
  - Re-validation after slimming the installed skill to `289` repo lines again
    reproduced the macOS SwiftUI/AppKit boundary on port `28902`. Artifacts:
    `/tmp/loupe-yattee-slimskill-blind-20260605-172705`. It used only grouped
    help/app/ui/act command families, proved `shapeView` alpha `1 -> 0.42`,
    preserved `unsupported_activation_target` for `ListTableRowView`, and
    reported that non-empty `reflect` candidates were still weak bridge hints.
- General fixes produced:
  - `ui audit` has no `--limit` option. Do not infer common flags across
    grouped commands; check current subcommand help before adding convenience
    flags in blind tasks.
  - Slim skill guidance now says non-empty SwiftUI/AppKit bridge `reflect`
    candidates can still be weak and must be compared with the observed
    hierarchy before patching.
  - `act tap` help now names `--ref <view-or-ax-ref>` so agents know saved view
    refs and accessibility refs are both valid selector refs.
  - Yattee is a better near-term macOS SwiftUI validation target than Gifski on
    this machine because it builds with the current Xcode and exposes useful
    SwiftUI/AppKit bridge, mutation, and action-boundary evidence without media
    conversion setup.

### LocationSimulator

- Repo: https://github.com/Schlaubischlump/LocationSimulator
- Revision: `bcad0d1988ceb405791acbab56faf15cfcbaf605`
- Platform: macOS AppKit
- UI: simulator/device sidebar, search field, split view, no-device placeholder,
  map/location workflow once a target device is selected.
- Why it matters: a real AppKit utility app exercises `NSOutlineView` rows,
  sidebar search chrome, split views, external device state, macOS host
  injection, visual mutation, and source reflection across Swift plus
  storyboard code.
- Build command:
  `xcodebuild -project LocationSimulator.xcodeproj -scheme LocationSimulator -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-locationsimulator-mac CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `de.davidklopp.locationsimulator`
- External-only automation patch:
  - Initialized the app's `Help` and `Localization` submodules.
  - Patched `/tmp/loupe-open-source-candidates/LocationSimulator/Help/Makefile`
    to generate a tiny fallback help page when `jekyll` is not installed,
    because the Help target otherwise fails before app UI validation.
- Working launch command:
  `open -n -F --stdout /tmp/loupe-locationsimulator-open.stdout.log --stderr /tmp/loupe-locationsimulator-open.stderr.log --env LOUPE_PORT=28769 --env LOUPE_BIND_HOST=127.0.0.1 --env CFFIXED_USER_HOME=/tmp/loupe-locationsimulator-home-open --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-locationsimulator-mac/Build/Products/Debug/LocationSimulator.app`
- Evidence:
  - Direct executable launch printed `LoupeInjector started` and then exited.
    LaunchServices `open --env` kept the AppKit app alive. Creating
    `/tmp/loupe-locationsimulator-home-open/Documents/logs` avoided the app's
    own logger setup error while keeping user defaults isolated.
  - `app info --host http://127.0.0.1:28769` returned a live macOS runtime for
    `de.davidklopp.locationsimulator`, PID `34637`.
  - `ui report --host http://127.0.0.1:28769` captured a real AppKit snapshot
    at `/tmp/loupe-locationsimulator-mac-report-main`: `234` view nodes,
    `109` accessibility nodes, `120` screen-map elements, `44` visible texts,
    `24` interactive elements, three scroll views, and no simulator screenshot,
    which is expected for this macOS runtime.
  - `ui tree /tmp/loupe-locationsimulator-mac-report-main/snapshot.json --accessibility`
    and `--view` exposed `NSWindow`, `NSSplitView`, `NoDeviceView`,
    `NSOutlineView`, `NSSearchField`, visible simulator/device names, and the
    placeholder text `No Device Selected`.
  - `ui query --text 'No Device Selected'` and `ui node` returned the AppKit
    `NSTextField` with style, constraints, parent `NoDeviceView`, and sibling
    placeholder image/detail label context.
  - Live `ui hit-test --point 650,420 --host http://127.0.0.1:28769` hit the
    visible `won의 iPhone` `NSTextField` and returned the useful responder
    chain through `NSTableCellView`, `NSTableRowView`, `NSOutlineView`,
    `SidebarViewController`, `SplitViewController`, `Window`, and
    `WindowController`.
  - Before the auto-backend fix, `act tap --ref n57 --host ...` failed by
    choosing the native simulator path and reporting multiple booted
    simulators. After the fix, the same command writes a trace with
    `backend: "runtime"` and no simctl selection error:
    `/tmp/loupe-locationsimulator-mac-trace-tap-device-auto-fixed`.
  - AppKit row selection remains a bounded action gap. Runtime tap on the text
    ref logs `activation_applied` but does not prove the device was selected;
    runtime tap on the `NSTableRowView` fails with
    `unsupported_activation_target` because the row view is not an `NSControl`.
  - `ui set --snapshot ... --ref n9 textColor --color '#ff3366'` changed the
    visible `No Device Selected` title. A fresh report at
    `/tmp/loupe-locationsimulator-mac-report-after-mutation` showed the red
    text color.
  - `ui reflect` on the mutation returned useful no-testID source candidates:
    `NoDeviceView.swift` IBOutlet declarations for `titleLabel` and
    `detailedLabel`, `NoDeviceViewController.swift` where the no-device title
    and message are set, plus `Main.storyboard` text-color entries. Artifact:
    `/tmp/loupe-locationsimulator-reflect-title-color.json`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result on a fresh port/home under
    `/tmp/loupe-locationsimulator-blind-report-main`. It verified launch and
    live `app info`, captured compact/screen/accessibility/view trees using
    the corrected tree argument order, discovered `No Device Selected` and
    `won의 iPhone`, confirmed the hit-test responder chain through the
    `NSOutlineView` sidebar, and showed that `act tap --ref n61 --host ...`
    records `backend: "runtime"` without the old multiple-booted-simulator
    failure. The fresh post-tap report still showed `No Device Selected`, so
    the blind agent also treated selection as an action boundary. Mutation and
    reflection were reproduced at
    `/tmp/loupe-locationsimulator-blind-title-color.json` and
    `/tmp/loupe-locationsimulator-blind-title-reflect.json`.
- General fixes produced:
  - `act tap --backend auto` now resolves to runtime activation for explicit
    non-simulator host tap targets, while keeping simulator runtimes on the
    existing native/auto path.
  - Skill guidance now shows the correct `ui tree "$SNAPSHOT" --accessibility`
    argument order and clarifies that macOS/linked host `auto` tap can avoid
    simulator UDID selection, but AppKit row selection still needs trace plus
    fresh-report proof.

### Gifski

- Repo: https://github.com/sindresorhus/Gifski
- Revision: `7f873856e2acd8b52e6681dee3aec31e6cab23e4`
- Platform: macOS SwiftUI/AppKit
- Outcome: currently blocked as a validation candidate on this machine.
- Evidence:
  - `xcodebuild -project Gifski.xcodeproj -list` failed before scheme
    discovery because the project file uses object version `100`, which this
    installed Xcode does not support.
- Guidance:
  - Keep it as a future macOS SwiftUI candidate, but do not spend agent cycles
    on it in this loop until the local Xcode toolchain can open the project or
    a compatible revision is selected.

### Ice

- Repo: https://github.com/jordanbaird/Ice
- Revision: `11edd39115f3f43a83ae114b5348df6a0e1741cf`
- Platform: macOS SwiftUI/AppKit
- UI: menu bar app with SwiftUI settings and permissions windows.
- Why it matters: a real menu bar SwiftUI app exposed non-window-first app
  lifecycle, hidden SwiftUI scene noise, and limited semantic/action visibility
  through AppKit hosting views.
- Build command:
  `xcodebuild -project Ice.xcodeproj -scheme Ice -destination 'platform=macOS' -configuration Debug -derivedDataPath /tmp/loupe-build-ice-mac CODE_SIGNING_ALLOWED=NO ENABLE_HARDENED_RUNTIME=NO build`
- Bundle ID: `com.jordanbaird.Ice`
- Launch command:
  `open -n -F --env LOUPE_PORT=28750 --env LOUPE_BIND_HOST=127.0.0.1 --env DYLD_INSERT_LIBRARIES=/Users/woody/Workspace/loupe/.build/arm64-apple-macosx/debug/libLoupeInjector.dylib /tmp/loupe-build-ice-mac/Build/Products/Debug/Ice.app`
- Evidence:
  - `ui report --host http://127.0.0.1:28750` captured a real macOS SwiftUI
    menu bar app. Artifacts: `/tmp/loupe-ice-mac-report-main`.
  - The visible tree exposed `PermissionsWindow` and its SwiftUI
    `AppKitWindowHostingView`, focus ring views, and `KeyViewProxy` nodes.
  - The hidden tree also contained `SettingsWindow` with SwiftUI/AppKit list
    internals. `--include-hidden` was required to see that hidden scene.
  - `ui compact` had no visible texts or interactive elements, and default
    accessibility only exposed the visible window. This is a current macOS
    SwiftUI semantic gap: window/hosting geometry is observable, but visible
    SwiftUI permission text and buttons were not available as actionable
    semantics.
  - `ui hit-test --point 900,730` hit the SwiftUI hosting view and returned an
    AppKit responder chain through `AppKitWindowHostingController`,
    `AppKitWindow`, `AppKitWindowController`, `AppKitApplication`, and
    `AppDelegate`. Artifact: `/tmp/loupe-ice-mac-hit-permission-button.json`.
  - `act tap --backend runtime --ref n169` on a visible `KeyViewProxy` failed
    with `unsupported_activation_target` because the matched view is not an
    `NSControl`. Artifact: `/tmp/loupe-ice-mac-trace-runtime-tap-keyproxy`.
  - Before the audit fix, `ui audit` reported 25 duplicate testID issues from
    the hidden `SettingsWindow`, even though the visible screen was the
    permissions window.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result. It relaunched through `open --env`, captured
    `/tmp/loupe-ice-mac-validation-20260605-031033/report`, confirmed
    `PermissionsWindow` was visible while `SettingsWindow` was hidden, verified
    compact output had no visible text/interactives without treating that as a
    report failure, hit-tested the SwiftUI hosting view, confirmed runtime tap
    failed with `unsupported_activation_target`, and verified `ui audit`
    returned `issueCount: 0` after the hidden duplicate-testID fix.
  - A second settings-window fixture run opened `SettingsWindow` directly with
    an external-only `LOUPE_OPEN_SETTINGS_WITHOUT_PERMISSIONS=1` app patch.
    Artifacts: `/tmp/loupe-ice-mac-report-settings` and blind rerun
    `/tmp/loupe-ice-blind-report-settings`.
  - The settings report exposed real SwiftUI/AppKit bridge structure:
    `SettingsWindow`, `NSSplitView`, `NSHostingView`, `HostingScrollView`,
    `ListCoreScrollView`, duplicated framework IDs `ListRow`/`ListCell`, and
    queryable `SwiftUIPopupButton` controls such as `Dot` and `Smart`.
  - Runtime activation on the `Dot` popup button found the correct accessibility
    target (`ax-n30`, role `button`, text `Dot`) but timed out through
    `/activate`. Artifacts:
    `/tmp/loupe-ice-mac-trace-dot-runtime-tap` and
    `/tmp/loupe-ice-blind-trace-dot-runtime-tap`. Treat this as a popup-button
    activation boundary and relaunch before continuing.
  - Runtime activation on a fresh `PlatformSwitch` target succeeded. The blind
    validation showed that `n18` was already value `1`, so agents must choose a
    fresh switch ref by current accessibility value instead of hard-coding a ref.
    It used `n33` and proved `0 -> 1` with `activation_applied` plus a fresh
    report. Artifact: `/tmp/loupe-ice-blind-trace-switch-runtime-tap`.
  - `ui set --snapshot ... --ref n30 alpha 0.42 --no-animate` on the `Dot`
    popup button succeeded. Fresh node inspection showed alpha `0.42`.
    `ui reflect` returned `sourceCandidates: []`, which is expected for this
    SwiftUI-generated `SwiftUIPopupButton`. Artifacts:
    `/tmp/loupe-ice-mac-dot-alpha-mutation.json`,
    `/tmp/loupe-ice-mac-report-after-dot-alpha`, and
    `/tmp/loupe-ice-mac-dot-alpha-reflect.json`.
- General fixes produced:
  - Layout audit now ignores hidden nodes when checking duplicate test IDs,
    matching the rest of the visible-node audit behavior. Re-running the Ice
    report after the fix produced `auditIssues: 0` at
    `/tmp/loupe-ice-mac-report-after-audit-fix`.
  - `ui mutations` capability rendering is more conservative for AppKit/SwiftUI
    bridge controls. `SwiftUIPopupButton` no longer advertises UIKit-only text
    styling mutations such as `textColor`, `textAlignment`, or `lineBreakMode`
    when the AppKit mutation backend would reject them.
  - This case should stay in the queue as a macOS SwiftUI semantic/action
    coverage target, not as a fully smooth action case.

### V2exOS iOS

- Repo: https://github.com/isaced/V2exOS
- Revision: `5859ececd425dcaf024a279fe0fa452e44d584f6`
- Platform: iOS SwiftUI on UIKit hosts
- UI: network-backed V2EX topic tabs, horizontally paged SwiftUI lists,
  topic-detail presentation, and long comment scroll views.
- Why it matters: the same real app that works as a tvOS focus case exposes a
  stronger iOS SwiftUI semantic boundary: screenshots clearly show Chinese
  topic titles, tab labels, authors, reply counts, and comments, while compact
  `visibleTexts` and text/staticText queries can be empty.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/V2exOS/V2exOS.xcodeproj -scheme V2exOSiOS -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-v2exos-ios CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.isaced.v2exos`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id com.isaced.v2exos --inject --port 28773 --timeout 45`
- Evidence:
  - `/tmp/loupe-v2exos-ios-report-relaunch` captured a real list screenshot
    with visible topic text and avatars. The summary had `534` nodes, `152`
    accessibility nodes, `23` screen-map elements, `8` interactive elements,
    `8` scroll views, and `visibleTexts: 0`.
  - `ui query --role cell` without `--include-hidden` returned only the current
    on-screen page cells. Raw hidden/offscreen inspection still shows the
    horizontally paged SwiftUI lists, so use default query/screen output for
    current-surface conclusions.
  - `ui hit-test --point 120,150` hit
    `CellHostingView<ModifiedContent<_ViewList_View, CollectionViewCellModifier>>`
    inside the visible first `ListCollectionViewCell`; the responder chain
    retained the useful collection/list context. Artifact:
    `/tmp/loupe-v2exos-ios-hit-first-row.json`.
  - `act tap --backend auto --snapshot ... --ref n25` opened the real topic
    detail. The trace at `/tmp/loupe-v2exos-ios-trace-tap-first-cell` showed
    new presentation/scroll-view nodes, and
    `/tmp/loupe-v2exos-ios-report-detail/screenshot.png` showed the topic
    body and comments even though compact `visibleTexts` stayed empty.
  - `act swipe --from 200,780 --to 200,340` on the detail view changed the
    detail `HostingScrollView` content offset from `0` to `732.67`; the fresh
    screenshot at `/tmp/loupe-v2exos-ios-report-detail-scrolled/screenshot.png`
    showed later comments.
  - `ui set --snapshot ... --ref n544 alpha 0.45` changed the detail
    `HostingScrollView` effective alpha and the fresh screenshot at
    `/tmp/loupe-v2exos-ios-report-mutated/screenshot.png` visibly faded the
    comments. `ui reflect` returned `sourceCandidates: []`, which is expected
    for a private SwiftUI `HostingScrollView` with no stable app class or test
    ID. Artifact: `/tmp/loupe-v2exos-ios-reflect-detail-alpha.json`.
  - The visual alpha mutation affected the SwiftUI presentation enough that
    continuing navigation from the mutated state produced a black detail shell.
    Relaunching the app restored a clean list. Treat this as a reminder to run
    broad visual mutations last or relaunch before continuing the user-flow
    scenario.
  - A coordinate `act tap --x 166 --y 92` switched the top tab/page. The trace
    at `/tmp/loupe-v2exos-ios-trace-tap-tab-all` showed page/list geometry
    replacement, and `/tmp/loupe-v2exos-ios-report-tab-all/screenshot.png`
    showed the selected underline and topic list moved to `分享创造`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result on a separate runtime port. It launched the prebuilt app at
    `http://127.0.0.1:28774`, confirmed `app current live: true`, verified
    `visibleTexts: []` and empty text queries for screenshot-visible tab/topic
    strings, hit-tested the first row, tapped the same-snapshot first cell ref,
    swiped the detail view to `contentOffset.y = 1043.33`, coordinate-tapped
    the `分享创造` tab, and mutated a SwiftUI host alpha with empty reflect
    candidates. Artifacts:
    `/tmp/loupe-v2exos-ios-blind-initial-20260605-073431`,
    `/tmp/loupe-v2exos-ios-blind-tap-first-cell-trace-20260605-073551`,
    `/tmp/loupe-v2exos-ios-blind-detail-swipe-trace-20260605-073625`,
    `/tmp/loupe-v2exos-ios-blind-tab-tap-trace-20260605-073736`,
    `/tmp/loupe-v2exos-ios-blind-after-mutation-20260605-073916`.
- General feedback:
  - iOS SwiftUI `TabView`/horizontal pager/list screens can be visually rich
    while text semantics are absent. Agents should pair screenshot evidence
    with hit-test, default role queries, same-snapshot refs, trace diffs, and
    fresh reports instead of assuming visible text is queryable.
  - Ref-based mutation of private SwiftUI host views is useful as a visual
    probe, but source reflection may legitimately be empty. Prefer stable
    app-authored test IDs/probes when a source edit suggestion is required.

### Harbour

- Repo: https://github.com/rrroyal/Harbour
- Revision: `e56c10cb376baaa3ada49b29b8396e1ab9293942`
- Platform: iOS SwiftUI on UIKit hosts
- UI: Docker/Portainer management app with onboarding, setup form, secure token
  field, tabs, lists, widgets, and AppIntents.
- Why it matters: a real SwiftUI form app exercises build setup with local
  packages, onboarding presentation surfaces whose visible text is not initially
  queryable, text-field focus/type behavior, mutation, and source reflection
  without needing a live Portainer server for the first route.
- Build setup:
  `git -C /tmp/loupe-open-source-candidates/Harbour submodule update --init --recursive`
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/Harbour/Harbour.xcodeproj -scheme Harbour -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-harbour-ios -skipPackagePluginValidation CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `xyz.shameful.Harbour`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id xyz.shameful.Harbour --inject --port 28775 --timeout 45`
- Evidence:
  - After submodule initialization, the app built and produced
    `/tmp/loupe-build-harbour-ios/Build/Products/Debug-iphonesimulator/Harbour.app`.
    The first failure was useful setup evidence: the app depends on the local
    `Modules/PortainerKit` submodule, and Xcode package plugin validation
    needs `-skipPackagePluginValidation` in unattended runs.
  - `/tmp/loupe-harbour-ios-report-main/screenshot.png` showed the onboarding
    card with `Hi! Welcome to Harbour!` and a bottom `Continue` CTA, but
    compact `visibleTexts` and text queries for `Continue` or `Harbour` were
    empty. The view tree still contained the underlying tab/list shell
    (`Containers`, `Stacks`), so agents must bind conclusions to screenshot,
    current-surface query, and hit-test evidence instead of treating all view
    tree text as the visible modal content.
  - `ui hit-test --point 200,800` hit the onboarding CTA's
    `UIPlatformGlassInteractionView`. A coordinate `act tap --x 200 --y 800`
    opened the setup form. Trace:
    `/tmp/loupe-harbour-ios-trace-tap-continue`; fresh report:
    `/tmp/loupe-harbour-ios-report-after-continue`.
  - The setup form exposed useful text fields with default role queries:
    `ui query --role textField` returned the URL field and a redacted token
    field. Without `--include-hidden`, the covered background search field was
    excluded.
  - Tapping the URL field by same-snapshot ref and typing `:9443` changed the
    field value to `:9443` rather than appending to the original URL, because
    the focused field selected the previous contents. Trace artifacts:
    `/tmp/loupe-harbour-ios-trace-tap-url-field` and
    `/tmp/loupe-harbour-ios-trace-type-url`; fresh report:
    `/tmp/loupe-harbour-ios-report-after-type`.
  - `ui set --snapshot ... --ref n198 alpha 0.35` visibly faded the large
    `Setup` title. Fresh report:
    `/tmp/loupe-harbour-ios-report-mutated`; mutation output:
    `/tmp/loupe-harbour-ios-set-setup-alpha.json`.
  - The initial `ui reflect` result returned a weak candidate under
    `Harbour/UI/Views/TextEditorView.swift` because the `alpha` property term
    matched `.alphabet`. After tightening source-term matching and boosting
    SwiftUI navigation-title literal hints, re-running reflect wrote
    `/tmp/loupe-harbour-ios-reflect-setup-alpha-after-ranking-fix.json`, with
    `SetupView.swift:156 .navigationTitle("SetupView.Title")` as the first
    candidate.
  - Fresh blind validation with the slim installed Loupe skill reproduced the
    same workflow on port `28897`: screenshot-only onboarding text/CTA, generic
    CTA hit-test plus coordinate tap, URL field replacement to `:9443`, secure
    token redaction, `Setup` title alpha proof, and the same
    `SetupView.swift:156` top reflect hint. Artifacts:
    `/tmp/loupe-harbour-slimskill-blind-20260605-174521`.
- General feedback:
  - SwiftUI onboarding or sheet content can be screenshot-visible while compact
    text and text queries are empty. Use hit-test/coordinate action plus fresh
    report evidence for the flow, and avoid reporting underlying view-tree text
    as visible modal semantics.
  - External `.app` bundles still need explicit `xcrun simctl install` before
    `loupe app launch`; launch attaches to a bundle ID, but is not a general
    installer.
  - `act type` sends text into the current selection. In form fields, the
    result can be replacement rather than append; always verify with a fresh
    report/query/node because trace metadata redacts the requested text.
  - A non-empty `ui reflect` result can still be weak when the mutated target is
    a UIKit label generated by SwiftUI navigation or presentation machinery.
    Reflection now avoids source-term substring false positives such as
    `alpha` matching `.alphabet`, but agents still need to read the candidate
    file before turning it into guidance or a patch.

### V2exOS TV

- Repo: https://github.com/isaced/V2exOS
- Revision: `5859ececd425dcaf024a279fe0fa452e44d584f6`
- Platform: tvOS SwiftUI
- UI: network-backed V2EX topic list with top tab focus and table-backed
  SwiftUI `List` rows.
- Why it matters: a real tvOS SwiftUI app exercises simulator injection,
  screenshot reports, focus movement, remote press traces, and UIKit-hosted
  SwiftUI list internals without requiring account setup.
- Build command:
  `xcodebuild -project V2exOS.xcodeproj -scheme V2exOSTV -destination 'generic/platform=tvOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-v2exos-tvos CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.isaced.v2exos`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=tvOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-appletvsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 3F0B2464-872D-4709-99E6-54AB53C37E07 --bundle-id com.isaced.v2exos --inject --port 28751 --timeout 30`
- Evidence:
  - `ui report --host http://127.0.0.1:28751 --udid 3F0B2464-872D-4709-99E6-54AB53C37E07`
    captured snapshot, compact, accessibility, screen-map, audit, logs, and a
    real tvOS simulator screenshot. Artifacts:
    `/tmp/loupe-v2exos-tvos-report-main`.
  - The initial report saw `63` nodes, `23` accessibility nodes, `23`
    interactive elements, two visible tab texts (`最热`, `最新`), and three
    scroll views.
  - `ui tree --view` exposed the SwiftUI `TabView` and `List` through UIKit
    hosts: `_UIHostingView`, `UIKitPlatformViewHost`, `UpdateCoalescingTableView`,
    `UITableViewWrapperView`, `ListTableViewCell`,
    `CellHostingView`, and `UITabBarButton`.
  - `ui tree --accessibility` exposed the table/list structure and tab buttons,
    but not every topic title as semantic text. Screenshot remains important
    for human-visible topic content in this app.
  - `act press right --trace-dir /tmp/loupe-v2exos-tvos-press-right-trace`
    moved focus from `最热` to `最新`; the trace includes before/after
    screenshots and a diff showing the tab focus geometry change.
  - `act press select --trace-dir /tmp/loupe-v2exos-tvos-press-select-latest-trace`
    switched into the latest-topic list. The trace diff showed list row
    changes and the screenshot showed the first topic row focused.
  - Re-running `ui report` after the audit fix produced
    `/tmp/loupe-v2exos-tvos-report-after-audit-fix` with `auditIssues: 0`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result. It installed the prebuilt app, launched with repo-local
    `./.build/debug/loupe`, captured
    `/tmp/loupe-v2exos-tvos-blind-validation-20260605-032822/report`, verified
    `auditIssues: 0`, found the `最热` accessibility tab button, moved focus
    with `act press right`, and selected into the latest list with
    `act press select`. Artifacts:
    `/tmp/loupe-v2exos-tvos-blind-validation-20260605-032822/trace-right`,
    `/tmp/loupe-v2exos-tvos-blind-validation-20260605-032822/trace-select`.
    The blind agent also confirmed that tvOS action proof should combine trace
    summary, fresh focused-node evidence, and screenshots; the `press right`
    summary had `changed=0` even though the focused tab moved.
- General fixes produced:
  - Layout audit now ignores synthetic nodes for small-target checks.
  - Layout audit no longer reports internal `UITabBarButton` small-target
    noise when the app has no stable test ID for the system tab bar view.
  - Layout audit allows scroll-container content to extend beyond the visible
    parent frame, which is normal for table/collection/scroll views.
  - Layout audit ignores tvOS focus-decoration containment noise from
    `_UIFloatingContent...` and `_UIFocus...` views.

### Swiftfin tvOS

- Repo: https://github.com/jellyfin/Swiftfin
- Revision: `9e77376e3292db82f9852c33de48bc9f00285f81`
- Platform: tvOS SwiftUI
- UI: real Jellyfin client onboarding and server connection flow, including
  tvOS focus, system text-entry UI, and SwiftUI/UIKit bridge text fields.
- Why it matters: this is a production-shaped tvOS app rather than a toy
  example. It exercises a heavier real build setup, SwiftUI surfaces that are
  screenshot-visible but sparse in Loupe semantics, and a UIKit-backed
  `TVTextField` that can be queried, typed into, mutated, and verified.
- Build notes:
  - Plain `xcodebuild` first failed because Swift macro targets from
    `swift-case-paths` and `StatefulMacros` required approval; adding
    `-skipMacroValidation` moved the build forward.
  - Swiftfin expects `Carthage/Build/TVVLCKit.xcframework`. Carthage was not
    installed locally, so the VLCKit `3.7.2` binary JSON from the app's
    `Cartfile` was used to download and unpack `TVVLCKit.xcframework`.
  - The repo already contains generated `Shared/Strings/Strings.swift`; for
    this runtime validation only, a temporary no-op `swiftgen` shim under
    `/tmp/loupe-swiftfin-bin` let the build script use the existing generated
    output. `SwiftFormat` and `SwiftLint` were not installed, but their scripts
    only emitted messages and the app build still succeeded.
- Build command:
  `PATH=/tmp/loupe-swiftfin-bin:$PATH xcodebuild -project /tmp/loupe-open-source-candidates/Swiftfin/Swiftfin.xcodeproj -scheme 'Swiftfin tvOS' -destination 'generic/platform=tvOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-swiftfin-tvos -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `org.jellyfin.swiftfin`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=tvOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-appletvsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 3F0B2464-872D-4709-99E6-54AB53C37E07 --bundle-id org.jellyfin.swiftfin --inject --port 28787 --timeout 45`
- Evidence:
  - Initial report `/tmp/loupe-swiftfin-tvos-report-main` captured the real
    Jellyfin start screen screenshot and runtime artifacts. It saw `16` view
    nodes, `6` accessibility nodes, and `0` visible texts even though the
    screenshot clearly showed Korean onboarding copy and a `연결` CTA. The
    view/accessibility trees exposed only high-level SwiftUI hosting and
    navigation bar nodes. This is a real SwiftUI semantic coverage boundary,
    not a blank app.
  - `act press select --trace-dir /tmp/loupe-swiftfin-tvos-press-select-connect-trace`
    opened the server connection screen. The trace diff introduced
    `TVTextField role=textField text="서버 URL"`, and fresh report
    `/tmp/loupe-swiftfin-tvos-report-connect` exposed the text field with
    `focused focusable` state.
  - Typing directly while the field was only focused did not change the value.
    After `act press select` activated the tvOS text-entry UI, report
    `/tmp/loupe-swiftfin-tvos-report-keyboard` showed the system keyboard and
    `완료` button. Then
    `act type 'http://10.0.0.2:8096' --trace-dir /tmp/loupe-swiftfin-tvos-type-url-active-trace`
    changed the field value; fresh report
    `/tmp/loupe-swiftfin-tvos-report-after-active-type` verified
    `TVTextField text="http://10.0.0.2:8096"`.
  - Pressing `select` on `완료` closed the keyboard. Report
    `/tmp/loupe-swiftfin-tvos-report-after-done` showed the typed value and the
    screenshot showed the `연결` button enabled, but `ui query --text '연결'`
    still returned empty because the button remained inside SwiftUI rendering.
  - `act press down --trace-dir /tmp/loupe-swiftfin-tvos-press-down-connect-trace`
    moved focus off the `TVTextField` and onto a `HostingView`, inferred to be
    the connect button region by screenshot/focus behavior. The actual button
    label was still not structurally queryable.
  - `act press select --trace-dir /tmp/loupe-swiftfin-tvos-press-connect-trace`
    produced a connection-attempt signal: the trace diff introduced
    `SwiftUIActivityIndicatorView` nodes in the navigation bar. Fresh report
    `/tmp/loupe-swiftfin-tvos-report-after-connect-press` showed the app back
    on the connection form. `debug logs` and `debug network` were empty for
    this attempt, so the evidence is visual/trace-based rather than request-log
    based.
  - `ui set --snapshot /tmp/loupe-swiftfin-tvos-report-after-connect-press/snapshot.json --ref n25 textColor --color '#ff3366'`
    changed the `TVTextField` color. Mutation output:
    `/tmp/loupe-swiftfin-tvos-set-textfield-color.json`; fresh report:
    `/tmp/loupe-swiftfin-tvos-report-after-textcolor`. The node style reported
    `textColor` as red `1`, green `0.2`, blue `0.4`, and the screenshot showed
    the URL in pink.
  - `ui reflect /tmp/loupe-swiftfin-tvos-set-textfield-color.json --source /tmp/loupe-open-source-candidates/Swiftfin`
    wrote `/tmp/loupe-swiftfin-tvos-reflect-textfield-color.json` with
    `sourceCandidates: []`. That is a bounded result here: the mutated runtime
    target is Apple internal `TVTextField` behind SwiftUI `TextField`, not an
    app-owned view type or stable test ID.
  - Blind validation with only the Loupe skill and target contract reproduced
    the launch, first report, connection-screen report, text-field query, text
    editing activation, and typed-value verification on port `28788`. Artifacts:
    `/tmp/loupe-swiftfin-tvos-validation-20260605-095029/01-first-screen`,
    `/tmp/loupe-swiftfin-tvos-validation-20260605-095029/02-connection-screen`,
    and
    `/tmp/loupe-swiftfin-tvos-validation-20260605-095029/05-after-type-keyboard-open`.
    The blind agent independently confirmed `visibleTexts: 0` on the first
    screenshot-visible CTA screen, `TVTextField ref=n25` on the connection
    form, and that typing only worked after `act press select` opened the tvOS
    text-entry UI. It stopped before mutation because it tried to dismiss
    `완료` with `act tap --ref ... --backend native`; the runtime host on port
    `28788` then became unreachable. The main run avoided that path by using
    `act press select`, which kept the runtime alive and allowed mutation and
    reflect checks to continue.
- General feedback:
  - Real tvOS SwiftUI apps can be fully actionable through screenshot and
    remote press traces while initial CTA text is absent from view and
    accessibility text queries.
  - tvOS text entry needs an activation step. A focused `TVTextField` may not
    accept `act type` until `act press select` opens the system text-entry UI;
    verify by fresh report rather than command success.
  - A SwiftUI-generated `TVTextField` is a good runtime mutation target, but
    reflect may correctly return no source candidates when there is no app
    class/test ID to rank.

### News tvOS

- Repo: https://github.com/dkhamsing/news
- Revision: `8aeac80fcae474a86f52088513b283d4b7104e7d`
- Platform: tvOS UIKit
- UI: real news reader with a tvOS tab bar, remote focus selection, table-backed
  category feeds, network-loaded article headlines, and full-screen imagery.
- Why it matters: this is a small but real tvOS app with a reliable build and no
  account setup. It proves the inject-only tvOS path can capture a rich UIKit
  view tree and drive remote navigation, not just launch a blank app.
- Build command:
  `xcodebuild -quiet -project /tmp/loupe-open-source-candidates/news/Xcode/TheNews.xcodeproj -scheme TheNews.tvos -destination 'generic/platform=tvOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-news-tvos CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES ARCHS=arm64 clean build`
- Bundle ID: `dk.TheNews-tvos`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=tvOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-appletvsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --bundle-id dk.TheNews-tvos --device 3F0B2464-872D-4709-99E6-54AB53C37E07 --inject --port 28817 --timeout 20`
- Evidence:
  - Initial report `/tmp/loupe-news-tvos-report-main` captured a real 1920x1080
    tvOS screenshot, snapshot, compact context, screen map, accessibility export,
    audit, runtime info, and logs.
  - The initial report saw `67` view nodes, `18` accessibility nodes, `14`
    interactive elements, `11` visible texts, `29` screen-map elements, and
    `auditIssues: 0`.
  - `ui screen /tmp/loupe-news-tvos-report-main/snapshot.json --limit 80` exposed
    UIKit-backed tab bar buttons (`General`, `Business`, `Entertainment`,
    `Health`, `Science`, `Sports`, `Technology`) and `TvNewsCell` rows with
    visible article labels.
  - `ui query /tmp/loupe-news-tvos-report-main/snapshot.json --exact-text Business --include-hidden`
    found the `Business` tab as an interactive `role=button` node.
  - `act press right --trace-dir /tmp/loupe-news-tvos-trace-right` moved the
    selected accessibility trait from `General` (`ax-n61`) to `Business`
    (`ax-n70`). Fresh report `/tmp/loupe-news-tvos-report-after-right` captured
    the Business tab selected and a different set of article headlines.
  - The before screen contained headlines such as `Elon Musk's SpaceX eyes
    $1.77tn valuation ahead of historic IPO`; the after screen contained
    Business headlines such as `Bitcoin selloff continues as prices slide below
    $63,000 for the first time since February`.
  - The trace target recorded `resolvedSource: remotePress:right`, so this proof
    stays on the tvOS remote path instead of coordinate or tap-style reasoning.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same inject-only result on a fresh port. Artifacts:
    `/tmp/loupe-blind-news-tvos-20260605-142547/report-before`,
    `/tmp/loupe-blind-news-tvos-20260605-142547/trace-press-right`,
    `/tmp/loupe-blind-news-tvos-20260605-142547/report-after-right`,
    `/tmp/loupe-blind-news-tvos-20260605-142547/node-before-general.txt`, and
    `/tmp/loupe-blind-news-tvos-20260605-142547/node-after-right-business.txt`.
    The blind run independently verified `General selected=true` before,
    `Business selected=true` after `act press right`, and the top article
    changing from `Elon Musk's SpaceX eyes $1.77tn valuation ahead of historic
    IPO` to `Bitcoin selloff continues as prices slide below $63,000 for the
    first time since February`.
- General feedback:
  - For UIKit tvOS apps, Loupe can observe selected tab traits directly in the
    accessibility export, which is stronger than screenshot-only focus evidence.
  - Saved snapshot paths are positional arguments for `ui screen`, `ui tree`, and
    `ui query`; do not pass them as `--snapshot` to those commands.
  - Trace directories include PNG files. When extracting proof in scripts, read
    the `*.json` trace files explicitly instead of piping every trace artifact to
    a text tool.

### Cronica

- Repo: https://github.com/eggerco/cronica
- Revision: `9f2fc824aaba7054f1221fd95112964f3c56cd60`
- Platform validated: iOS SwiftUI on UIKit hosts
- Platforms blocked locally in this pass:
  - tvOS and watchOS builds fail because `YouTubePlayerKit` imports unavailable
    `WebKit` for those destinations. Logs:
    `/tmp/loupe-build-cronica-tvos.log`,
    `/tmp/loupe-build-cronica-watch.log`.
  - visionOS build fails in `Shared/View/Navigation/SearchView.swift` because
    `UIDevice.isIPad` is not available for that target. Log:
    `/tmp/loupe-build-cronica-vision.log`.
- UI: onboarding sheet, tab bar, SwiftUI `.searchable` search screen, segmented
  filters, UIKit search field internals.
- Why it matters: a real multiplatform SwiftUI app reproduced three practical
  agent boundaries: screenshot-visible onboarding that is sparse in queries,
  synthetic tab bar refs that need native fallback, and SwiftUI `.searchable`
  text fields where runtime activation logs are not enough to prove typing
  focus.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/cronica/Cronica.xcodeproj -scheme 'Cronica (EN-US)' -destination 'generic/platform=iOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-cronica-ios CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `dev.alexandremadeira.Story`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=iOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-iphonesimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device C1B36E72-6491-4E0F-A73C-C3D5D3E1ADC7 --bundle-id dev.alexandremadeira.Story --inject --port 28763 --timeout 40`
- Evidence:
  - The onboarding report at `/tmp/loupe-cronica-ios-report-main` captured a
    real screenshot with `Cronica`, `Your Watchlist`, `Always Synced`,
    `Continue`, and `Privacy Policy`, but `ui query --text Continue` and
    `ui query --role button` returned empty results. Use screenshot plus
    hit-test/coordinate evidence for this sheet.
  - `act tap --backend native --x 116 --y 789` dismissed onboarding. Trace:
    `/tmp/loupe-cronica-ios-continue-tap-trace`. Fresh report:
    `/tmp/loupe-cronica-ios-report-after-continue`, where `ui query --text Home`
    found the tab content.
  - `ui query --text Search` found the Search tab ref. Runtime tap on that ref
    failed with `unsupported_target` because the matched tab item is synthetic
    and not backed by a `UIView`. `act tap --backend auto` on the same ref
    succeeded through native coordinates. Trace:
    `/tmp/loupe-cronica-ios-search-auto-tap-trace`.
  - The Search report at
    `/tmp/loupe-cronica-ios-report-search-after-audit-fix` produced
    `auditIssues: 0` after the general audit-noise fixes below.
  - `ui hit-test --point 90,190` resolved the search field as
    `UISearchBarTextField`. Runtime activation on the field logged
    `activation_applied`, but typing did not change the value until the field
    was focused with a native coordinate tap. Native focus plus
    `act type 'Dune'` succeeded; trace metadata redacted the input as
    `<redacted>`. Fresh report:
    `/tmp/loupe-cronica-ios-report-after-type-success`.
  - Re-running audit before deliberate mutation reduced the Search screen to
    two remaining `missingTestID` hints: the system search cancel `UIButton`
    and `UISegmentedControl`. These are source-quality hints, not layout
    defects. Artifact:
    `/tmp/loupe-cronica-ios-report-after-type-audit-fix`.
  - `ui set --ref n57 textColor --color '#ff3366' --no-animate` changed the
    visible search text. A fresh report at
    `/tmp/loupe-cronica-ios-report-after-textcolor-mutation` showed
    `style.textColor` red `1`, green `0.2`, blue `0.4`, and the screenshot
    showed the pink `Dune` value.
  - `ui reflect` on the search-field mutation produced no source candidates.
    This is a useful bounded result: the target is a UIKit search field created
    by SwiftUI `.searchable`, with no stable app class or test ID to search.
    Artifact: `/tmp/loupe-cronica-ios-search-textcolor-reflect.json`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same flow under `/tmp/loupe-cronica-blind-validation-20260605`. It
    verified the onboarding screenshot/query gap, native Continue tap,
    synthetic Search tab runtime failure plus auto fallback, search-field
    hit-test, native focus, redacted `act type 'Dune'` trace metadata, visible
    `Dune` text-field query, text-color mutation, and `sourceCandidates: []`
    for the SwiftUI `.searchable` reflection case.
  - The blind agent found one new CLI rough edge: a saved report ref can drift
    before a live `ui set --ref` call because mutation runs against the current
    runtime snapshot. In that run, saved ref `n96` resolved live as `UITabBar`.
    `ui set --snapshot <saved-snapshot> --ref n96 ...` now resolves the saved
    node back to the current live `UISearchBarTextField` ref `n57`. Artifact:
    `/tmp/loupe-cronica-blind-validation-20260605/textcolor-snapshot-ref-mutation.json`.
- General fixes produced:
  - Layout audit now ignores system tab bar item overlap noise.
  - Layout audit ignores scroll containers for small-target checks.
  - Layout audit ignores text-field placeholder label contrast noise while
    preserving real low-contrast app text findings.
  - Layout audit ignores private text-editing implementation views for child
    containment checks.
  - Layout audit does not report standard no-testID `UISegmentedControl`
    height as a small touch-target defect.
  - `ui set` now accepts `--snapshot <snapshot.json>` so ref-based mutations
    can resolve a saved snapshot ref to the corresponding live runtime ref
    before applying the mutation.
  - Skill guidance now tells agents to prove SwiftUI `.searchable` text input
    with fresh value evidence, not runtime activation logs alone.

### Gym Routine Tracker Watch

- Repo: https://github.com/open-trackers/Gym-Routine-Tracker-Watch-App
- Revision: `a7b48ba38f3660afcd036c632d6745d1523faf63`
- Platform: watchOS SwiftUI
- UI: independent watch app with a routine list, add-routine route, settings,
  widgets, Core Data, and CloudKit-backed storage.
- Why it matters: a real watchOS app clarified the useful Loupe boundary:
  simulator injection can start the runtime and capture the watch screen, but
  app-authored probes are required for meaningful SwiftUI geometry.
- Build command:
  `xcodebuild -project 'Gym Routine Tracker Watch.xcodeproj' -scheme 'Gym Routine Tracker Watch' -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-grt-watch-signed CODE_SIGN_IDENTITY=- build`
- Bundle ID: `org.openalloc.grout.watch`
- External-only automation patches:
  - Patched the checked-out `TrackerUI` dependency under DerivedData to qualify
    `Foundation._FormatSpecifiable`; current Xcode otherwise reports an
    ambiguous `_FormatSpecifiable` conformance.
  - Added two no-import `GeometryReader` probes to the candidate app's
    `ContentView` under `/tmp`: `grt.routines.root` and `grt.routines.list`.
    The helper posts `dev.loupe.probe` / `dev.loupe.removeProbe` notifications
    and does not import `LoupeKit`.
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=watchOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-watchsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 329EE5CA-1579-43FE-BA8B-FC42A3229FAE --bundle-id org.openalloc.grout.watch --inject --port 28753 --timeout 30`
- Evidence:
  - The same watch simulator passed the repo's `LoupeWatchExample` E2E before
    validating this app, so the watchOS injector/runtime baseline was known
    good.
  - Without app-authored probes, `ui report` reached the runtime and produced a
    watch simulator screenshot, but the snapshot had only the `WKApplication`
    root. This is the expected watchOS inject-only boundary, not an app query
    failure.
  - The watchOS runtime now reports real screen metadata from
    `WKInterfaceDevice`: `208x248` at scale `2` for the tested Series 11
    simulator.
  - With the local no-import probe helper, `ui report` captured three nodes,
    two accessibility nodes, two screen-map elements, and `auditIssues: 0`.
    Artifacts: `/tmp/loupe-grt-watch-report-probes-parent`.
  - `ui tree --view` reconstructed probe containment:
    `WKApplication -> grt.routines.root -> grt.routines.list`.
  - `ui tree --accessibility` exposed the same probe labels as accessibility
    groups.
  - `act tap --x 104 --y 91 --trace-dir /tmp/loupe-grt-watch-tap-add-trace`
    dispatched simulator input and produced a trace diff. Because there are no
    automatic watchOS semantics for the destination screen, prove action
    results with app-authored probes or fresh defaults/log evidence rather than
    command success alone.
  - Blind validation after terminate/uninstall/install reproduced the useful
    geometry path: `208x248 @2x`, `auditIssues: 0`, and
    `WKApplication -> grt.routines.root -> grt.routines.list`. It also exposed
    a backend trap: `act tap --backend runtime` on the watch runtime timed out
    fetching a post-action snapshot, so watchOS task contracts should prefer
    native/auto coordinate actions and a fresh report/log/defaults check.
    Artifacts: `/tmp/loupe-grt-watch-report`,
    `/tmp/loupe-grt-watch-tap-trace`.
- General fixes produced:
  - watchOS snapshots now include screen size/scale from `WKInterfaceDevice`
    instead of reporting `0x0`.
  - watchOS registered probes are organized by frame containment, so nested
    SwiftUI probes appear as parent/child nodes instead of overlapping siblings.
  - The queue now treats watchOS inject-only view trees as a limited mode and
    recommends no-import local probes for real SwiftUI screens that need
    stable bounds.

### SafeTimer Watch

- Repo: https://github.com/hortelanos/SafeTimer
- Revision: `b133c10a82c9a3187e41207f94ad36f1d0f496b5`
- Platform: watchOS SwiftUI inside a WatchKit extension
- UI: real timer list, new-timer form, settings route, Core Data storage,
  localized strings, and complications.
- Why it matters: this is a second real watchOS app that goes beyond the
  inject-only boundary. With no-import local probes, Loupe can query meaningful
  watch screen regions, tap an actionable row by same-snapshot ref through the
  native simulator path, and verify route change with trace/fresh-report
  evidence.
- Build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/SafeTimer/SafeTimer.xcodeproj -scheme SafeTimerWatch -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-safetimer-watch CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `asiergmorato.Mascarillas.watchkit`
- External-only automation patches:
  - Added a no-import `GeometryReader` probe helper to
    `SafeTimerWatch Extension/View/ContentView.swift`. It posts
    `dev.loupe.probe` / `dev.loupe.removeProbe` notifications and does not
    import `LoupeKit`.
  - Added probes for `safetimer.root`, `safetimer.newTimerRow`,
    `safetimer.settingsRow`, `safetimer.addForm`, and
    `safetimer.addForm.saveButton`.
  - The helper must use `background(GeometryReader { ... })`, not the
    watchOS-8-only `background { ... }` spelling, because this project targets
    watchOS 7.
- Probe build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/SafeTimer/SafeTimer.xcodeproj -scheme SafeTimerWatch -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-safetimer-watch-probes CODE_SIGNING_ALLOWED=NO build`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=watchOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-watchsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 329EE5CA-1579-43FE-BA8B-FC42A3229FAE --bundle-id asiergmorato.Mascarillas.watchkit --inject --port 28794 --timeout 45`
- Evidence:
  - Baseline report `/tmp/loupe-safetimer-watch-report-baseline` captured the
    real SafeTimer screenshot with `SafeTimer`, `New timer`, and `Settings`, but
    the snapshot had only one `WKApplication` node, no accessibility nodes, and
    `visibleTexts: 0`. This is the expected no-probe watchOS boundary.
  - After adding probes, report `/tmp/loupe-safetimer-watch-report-probes-main2`
    captured `4` nodes, `3` accessibility nodes, `3` screen-map elements, and
    `visibleTexts: 3` on a `208x248 @2x` screen.
  - `ui tree --view` reconstructed:
    `WKApplication -> safetimer.root -> safetimer.newTimerRow` and
    `safetimer.settingsRow`.
  - Default `ui query --test-id safetimer.newTimerRow` returned ref `n1`, and
    `ui node --fields node` showed `custom.loupe.probe=true` and
    `source=local-fallback`.
  - `act tap --ref n1 --snapshot ... --backend native --udid 329EE5CA-1579-43FE-BA8B-FC42A3229FAE --host http://127.0.0.1:28794 --trace-dir /tmp/loupe-safetimer-watch-tap-new-trace --expect-visible safetimer.addForm`
    opened the add-timer form. `debug trace summary` reported appeared probes
    `safetimer.addForm` and `safetimer.addForm.saveButton`.
  - Fresh report `/tmp/loupe-safetimer-watch-report-addform-fixed` verified the
    add form with `3` nodes, `2` accessibility nodes, `2` visible texts, and
    `auditIssues: 0`.
  - `ui audit` originally flagged an `overlappingSiblings` issue between
    form-level and button-level probe nodes. That was an audit false positive
    because probes are observation annotations, not real UI. After the core fix,
    the same add-form report audits cleanly.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same loop on port `58326`: initial report, compact/screen/tree output,
    query/node for `safetimer.newTimerRow`, same-snapshot `act tap --ref n1`
    with `--backend auto`, appeared probes `safetimer.addForm` and
    `safetimer.addForm.saveButton`, fresh add-form report, and `ui audit`
    issue count `0` on both snapshots. Artifacts:
    `/tmp/loupe-safetimer-watch-validation-20260605-0001`.
  - The blind agent also confirmed the command-surface detail that
    `app current --host` is not available; for a host-selected watch runtime,
    successful `ui report --host ...` is the runtime-health proof.
- General fixes produced:
  - `ui query` help now lists the options it already accepted:
    `--exact-text`, `--udid`, `--include-hidden`, `--max-results`, and
    `--timeout`.
  - Layout audit ignores overlap between Loupe probe nodes while preserving
    normal overlap findings for app UI.
  - Skill guidance now tells agents to keep watchOS probes sparse and actionable:
    overlapping broad parent probes can hide child probes from default current
    surface discovery; use `--include-hidden` for diagnosis or adjust the probe
    placement.

### Magic Tap Watch

- Repo: https://github.com/superturboryan/Magic-Tap
- Revision: `d83e43b2fe4f0a76201a263f26d1f886fabc4e7b`
- Platform: watchOS SwiftUI with an iOS companion app and local SwiftPM
  dependencies.
- UI: first-launch onboarding sheet, scrollable setup instructions, Continue
  button, main Digital Crown picker, WatchConnectivity-backed selected action
  state, and a double-pinch hidden action button.
- Why it matters: this is a third real watchOS app with a different shape from
  Gym Routine Tracker and SafeTimer. It exposed dependency setup friction, a
  first-launch SwiftUI sheet, offscreen ScrollView probe frames, and an
  underlying main-screen probe that is queryable while the screenshot still
  shows the onboarding sheet.
- Build setup:
  - The app references sibling local packages, so the validation checkout also
    needs `/tmp/loupe-open-source-candidates/ControlKit` and
    `/tmp/loupe-open-source-candidates/DoublePinch`.
  - The current `ControlKit` no longer exposes `Control.Flashlight`, so the
    external test fixture no-ops the companion iOS flashlight action in
    `Phone App/PhoneView.swift`. This is app/dependency drift, not a Loupe
    runtime issue.
- Build command:
  `xcodebuild -project '/tmp/loupe-open-source-candidates/Magic-Tap/Magic Tap.xcodeproj' -scheme 'watchOS App' -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-magic-tap-watch-probes CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `com.RyanDF.Magic-Tap.watchkitapp`
- External-only automation patches:
  - Added sparse no-import `GeometryReader` probes to
    `Watch App/WatchView.swift`: `magictap.root`,
    `magictap.actionPicker`, `magictap.info.root`, and
    `magictap.info.continue`.
  - The helper posts `dev.loupe.probe` / `dev.loupe.removeProbe` notifications
    and does not import `LoupeKit`.
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=watchOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-watchsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 329EE5CA-1579-43FE-BA8B-FC42A3229FAE --bundle-id com.RyanDF.Magic-Tap.watchkitapp --inject --port 28821 --timeout 40`
- Evidence:
  - Baseline report `/tmp/loupe-magic-tap-watch-report-baseline` captured the
    real first-launch Magic Tap screenshot, but the snapshot had only one
    `WKApplication` node, zero accessibility nodes, and `visibleTexts: 0`.
    This matches the expected inject-only watchOS boundary.
  - Probe report `/tmp/loupe-magic-tap-watch-report-probes-main` captured a
    `208x248 @2x` watch screen with `5` nodes, `4` accessibility nodes,
    `2` screen-map elements, `1` interactive element, and `auditIssues: 0`.
  - `ui query --test-id magictap.info.continue` returned no default result
    before scrolling because the Continue button was below the visible
    ScrollView viewport. The same query with `--include-hidden` returned
    `n2` at `6,519.5,178,52.5`, proving the probe existed but was offscreen.
  - The underlying `magictap.actionPicker` probe was queryable while the
    screenshot still showed the onboarding sheet. This is a useful watchOS
    probe boundary: queryable registered probes are runtime geometry evidence,
    but screenshot and current-surface evidence decide which workflow is
    actually visible.
  - `act swipe --from 104,210 --to 104,60 --backend auto --udid ...` scrolled
    the sheet. Fresh report `/tmp/loupe-magic-tap-watch-report-after-scroll`
    showed the Continue button in the screenshot and default
    `ui query --test-id magictap.info.continue` returned it at
    `6,187.5,178,52.5`.
  - Same-snapshot
    `act tap --ref n2 --snapshot /tmp/loupe-magic-tap-watch-report-after-scroll/snapshot.json --backend auto --expect-visible magictap.actionPicker`
    dismissed the onboarding sheet. Fresh report
    `/tmp/loupe-magic-tap-watch-report-after-continue` showed the main
    `Selected Action` picker screenshot, `magictap.actionPicker` was queryable,
    and `magictap.info.continue` was absent from default query.
  - Blind validation reproduced the flow under
    `/tmp/loupe-magic-tap-watch-blind-*`. It also found two real-app timing
    edges: the first `ui report --timeout 20` can time out on watchOS even when
    the app process is alive, and an immediate post-dismiss report can briefly
    retain a stale `magictap.info.continue` probe. Relaunching the same build
    and using a 60-second first report succeeded; waiting two seconds and
    recapturing after the tap produced the stable state with only
    `magictap.root` and `magictap.actionPicker`.
- General fixes produced:
  - Skill guidance now warns that a watchOS registered probe can be queryable
    while it is offscreen or belongs to an underlying screen behind a SwiftUI
    sheet. Pair `ui screen`, fresh screenshots, and default-vs-`--include-hidden`
    query results before acting.
  - WatchOS scroll workflows should bring a probed target into the default
    current surface before same-snapshot tap. An offscreen `--include-hidden`
    probe is discovery evidence, not an action target.
  - WatchOS route assertions should allow a short stabilization recapture after
    sheet dismissal or navigation. Treat `--expect-visible` as a useful guard,
    but do not let it replace a fresh screenshot/report for the destination
    workflow.

### Brush Watch

- Repo: https://github.com/BastiaanJansen/brush
- Revision: `4f1470e22803bddcde29e9726d70e1608e365e9f`
- Platform: watchOS SwiftUI inside a WatchKit extension
- UI: real toothbrush timer with a paged settings/start/history shell,
  HealthKit permission, a timer route, and duration controls.
- Why it matters: this real watchOS app exposed three general boundaries:
  ad-hoc signing can be required even for simulator watch extensions, native
  watchOS actions need stabilized evidence after transient transitions, and
  synthetic probes must not occlude other synthetic probes in current-surface
  discovery.
- Baseline build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/brush/Brush.xcodeproj -scheme 'Brush WatchKit App' -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-brush-watch-signed CODE_SIGN_IDENTITY=- build`
- Bundle IDs:
  - Watch app: `com.bastiaanjansen.Brush.watchkitapp`
  - Extension runtime: `com.bastiaanjansen.Brush.watchkitapp.watchkitextension`
- External-only automation patches:
  - Added no-import `GeometryReader` probes to the candidate app:
    `brush.root`, `brush.startButton`, `brush.timer`, `brush.result`,
    `brush.settings`, `brush.settings.minus`, and `brush.settings.plus`.
    The helper posts `dev.loupe.probe` / `dev.loupe.removeProbe` and adds
    `metadata.source=local-fallback`.
  - Added `LOUPE_SKIP_HEALTHKIT=1` to bypass the real HealthKit prompt when the
    scenario is app UI validation rather than system-permission validation.
  - Added `LOUPE_SKIP_EXTENDED_SESSION=1` to bypass
    `WKExtendedRuntimeSession` while isolating app UI behavior. This did not
    change the transient timer-route behavior, so the route instability was not
    caused only by the extended runtime session.
- Probe build command:
  `xcodebuild -project /tmp/loupe-open-source-candidates/brush/Brush.xcodeproj -scheme 'Brush WatchKit App' -destination 'generic/platform=watchOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-brush-watch-probes-stable CODE_SIGN_IDENTITY=- build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-watchsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 329EE5CA-1579-43FE-BA8B-FC42A3229FAE --bundle-id com.bastiaanjansen.Brush.watchkitapp --inject --port 28804 --env LOUPE_SKIP_HEALTHKIT=1 --env LOUPE_SKIP_EXTENDED_SESSION=1 --timeout 20`
- Evidence:
  - A `CODE_SIGNING_ALLOWED=NO` watch build installed but the extension was
    killed by AMFI with `has no CMS blob` / `Unrecoverable CT signature issue`.
    Rebuilding with `CODE_SIGN_IDENTITY=-` fixed the simulator launch.
  - Baseline no-probe report
    `/tmp/loupe-brush-watch-report-baseline` captured the real Brush start
    screenshot, but the snapshot had one `WKApplication` node and no semantic
    nodes. This is the expected inject-only watchOS boundary.
  - Probe report `/tmp/loupe-brush-watch-report-skiphealth-main` captured
    `brush.root` and `brush.startButton` on a `208x248 @2x` screen.
  - Tapping `brush.startButton` without the HealthKit bypass opened the Korean
    system Health access sheet. App snapshot still described the covered start
    screen, so the proof was the trace screenshot, not app text/query output.
  - With `LOUPE_SKIP_HEALTHKIT=1`, same-snapshot
    `act tap --ref n2 --snapshot ... --backend native --expect-visible brush.timer`
    produced a trace where `brush.timer` appeared. A stabilized report
    0.3 seconds later returned to the start screen, and a 0-second follow-up
    screenshot showed the timer route mid-transition off the right edge. Treat
    this as a real app navigation/lifecycle boundary: `--expect-visible` proves
    the transient appeared probe, not stable workflow completion.
  - `act swipe --from 62,128 --to 176,128 --udid ... --host ... --duration 0.25`
    moved the paged shell from Start to Settings. Stable trace/report artifacts:
    `/tmp/loupe-brush-watch-parenttie-swipe` and
    `/tmp/loupe-brush-watch-parenttie-settings`, with `brush.settings`,
    `brush.settings.minus`, and `brush.settings.plus`.
  - Before the probe visibility fix, `ui query --test-id brush.settings.plus`
    on the settings snapshot returned empty unless `--include-hidden` was used,
    because the broad synthetic settings probe was treated as painting over the
    plus/minus probes. After the core fix, default `ui query` finds
    `brush.settings.plus`.
  - Before the watchOS parent tie-breaker, equal-size root/settings probes could
    keep `brush.settings.plus` under the broad root in `ui tree --view`. The
    stable trace at `/tmp/loupe-brush-watch-parenttie-swipe` now renders
    `brush.settings` with `brush.settings.minus` and `brush.settings.plus` as
    children.
  - Same-snapshot `act tap --ref n4 --snapshot ... --backend native` succeeded
    against `/tmp/loupe-brush-watch-parenttie-settings/snapshot.json`. The trace
    at `/tmp/loupe-brush-watch-parenttie-plus` resolved the target to
    `brush.settings.plus` at `(156.25,192)`.
  - The plus tap trace had no snapshot diff because the probes did not encode
    the numeric duration. A fresh screenshot at
    `/tmp/loupe-brush-watch-parenttie-plus-after/screenshot.png` showed the
    value changed from `120 sec.` to `130 sec.`. For probe-only watchOS screens,
    screenshot or app-authored state evidence can be the state assertion even
    when the probe tree is unchanged.
  - Blind validation without prior context captured
    `/tmp/loupe-brush-watch-blind-main` and
    `/tmp/loupe-brush-watch-blind-swipe`. The swipe command timed out, but its
    after-snapshot and failure screenshot showed Settings with
    `brush.settings.plus` queryable by default. That run did not prove the plus
    tap: `/tmp/loupe-brush-watch-blind-plus/failure.png` still showed
    `120 sec.`, so it correctly reported the final `130 sec.` assertion as
    unresolved.
- General fixes produced:
  - `LoupeSurfaceVisibility` no longer treats `custom.loupe.probe=true` nodes
    as paint occluders. Synthetic probes remain queryable based on frame and
    real occlusion, but they do not hide sibling/child probes.
  - `LoupeAgentWatchOS` now avoids equal-size probe parent cycles and uses a
    later-registration tie-breaker for equal-size parent candidates, which keeps
    same-screen controls under their current screen probe.
  - CLI HTTP fetches now race `URLSession` against an explicit async timeout,
    so a runtime whose main actor is blocked fails within the requested timeout
    instead of hanging a long action/report command.
  - Action traces treat runtime logs as best-effort, so a slow `/logs` endpoint
    does not turn an otherwise successful swipe/tap trace into a failure.
  - Grouped `act` help now documents `--timeout` for tap, swipe, drag, type, and
    press; the blind run initially caught this as a command-help gap.
  - Skill guidance should prefer default query after this fix; use
    `--include-hidden` for watchOS probes only when diagnosing offscreen,
    underlying, or stale probe state.

### HandsRuler Vision

- Repo: https://github.com/FlipByBlink/HandsRuler
- Revision: `c0e4042d2703bc53fdf7a71d13d30f535ac784ab`
- Platform: visionOS SwiftUI/RealityKit
- UI: real Apple Vision Pro measuring app with a windowed SwiftUI shell,
  ARKit/hand-tracking measurement surface, toolbar, onboarding imagery, and a
  Start action.
- Why it matters: it proves visionOS Simulator injection can observe a real
  spatial app, and it exposes the coordinate/action boundary between the app's
  600x600 window snapshot and the full compositor screenshot.
- Build command:
  `xcodebuild -project HandsRuler.xcodeproj -scheme HandsRuler -destination 'generic/platform=visionOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-handsruler-vision CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `net.aaaakkkkssssttttnnnn.HandsWidth`
- Injector setup:
  `xcodebuild -scheme LoupeInjector -destination 'generic/platform=visionOS Simulator' -configuration Debug build`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-xrsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 40ABB5AB-E81B-4636-BACB-DCE10E5CC049 --bundle-id net.aaaakkkkssssttttnnnn.HandsWidth --inject --port 28756 --timeout 40`
- Evidence:
  - `LoupeInjector` built for `Debug-xrsimulator`, the app installed on Apple
    Vision Pro Simulator, and `app launch --inject` reported
    `http://127.0.0.1:28756`.
  - `ui report` captured a full visionOS screenshot plus Loupe artifacts.
    Artifacts: `/tmp/loupe-handsruler-vision-report`.
  - The screenshot shows the real room compositor with a floating HandsRuler
    app window. The snapshot screen is the app window coordinate space:
    `600x600 @1x`, not the full compositor screenshot.
  - The view tree exposed `UIApplication`, `UIWindowScene`, `UIWindow`,
    SwiftUI hosting views, `UIKitNavigationBar`, and SwiftUI-backed drawing
    surfaces. It found 53 nodes, 10 accessibility nodes, 11 screen-map
    elements, and one visible text: `HandsRuler`.
  - `ui query --text Start` found no results even though the screenshot showed
    a green Start button. The visible label is rendered inside SwiftUI drawing
    views, so agents should use hit-test, frame/style evidence, or app-authored
    probes instead of assuming visible text is queryable.
  - `ui hit-test --point 522,46` hit `CGDrawingView` with a responder chain
    through `UIKitBarItemHost<BarItemView>`, `UIKitNavigationController`,
    `UIKitTabBarController`, `UIWindow`, `UIWindowScene`, and the app delegate.
    Artifact: `/tmp/loupe-handsruler-vision-hit-start.json`.
  - `act tap --backend runtime --ref n26` failed with
    `unsupported_activation_target` because the matched Start-like host view is
    not a `UIControl`.
  - Native/auto app-window coordinate taps produced traces but no verified
    route change. Artifact:
    `/tmp/loupe-handsruler-vision-native-tap-trace`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same boundary. It relaunched on port `28757`, captured
    `/tmp/loupe-handsruler-vision-blind-20260605-041906/baseline-report`,
    confirmed `ui query --text Start` returned `[]`, found only the disabled
    navigation-title button for `--role button`, hit-tested the visual Start
    region as `CGDrawingView`, and verified that a coordinate tap trace did not
    prove a transition. Runtime ref tap on the hit-test drawing view did not
    resolve to an action target.
- General fixes produced:
  - The queue now treats visionOS screenshot evidence and snapshot geometry as
    related but distinct coordinate spaces.
  - The skill should warn that SwiftUI-rendered visionOS labels may be visible
    in screenshots while absent from text queries.
  - Runtime activation on visionOS should be treated like the existing
    UIKit/AppKit boundary: supported controls may work, but SwiftUI host/drawing
    views need hit-test/responder evidence or app-authored probes/logs before
    claiming action success.

### PersonaChess Vision

- Repo: https://github.com/FlipByBlink/PersonaChess
- Revision: `d93ece4236f8ece01dec41d785c7376032850867`
- Platform: visionOS SwiftUI/RealityKit
- UI: real Apple Vision Pro chess board app with a spatial board, pieces,
  bottom toolbar, SharePlay-related setup surfaces, and RealityKit content.
- Why it matters: it is a drawing/spatial-content-heavy visionOS app. It
  exposes a stronger boundary than HandsRuler: the full screenshot can show a
  usable chess board and toolbar while the target app snapshot only exposes the
  root SwiftUI hosting view and zero-height ornament implementation nodes.
- Build command:
  `xcodebuild -project PersonaChess.xcodeproj -scheme PersonaChess -destination 'generic/platform=visionOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-personachess-vision CODE_SIGNING_ALLOWED=NO build`
- Bundle ID: `net.aaaakkkkssssttttnnnn.PersonaChess`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-xrsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --device 40ABB5AB-E81B-4636-BACB-DCE10E5CC049 --bundle-id net.aaaakkkkssssttttnnnn.PersonaChess --inject --port 28758 --timeout 40`
- Evidence:
  - The app installed on Apple Vision Pro Simulator and launched with Loupe at
    `http://127.0.0.1:28758`.
  - `ui report` captured artifacts at
    `/tmp/loupe-personachess-vision-report`: screenshot `3840x2160`, target
    snapshot `870x870 @1x`, 399 view nodes, 3 accessibility nodes, one audit
    issue, and zero visible texts.
  - The screenshot showed PersonaChess's spatial board, chess pieces, and
    bottom toolbar. It also still showed a previously opened HandsRuler window,
    proving that visionOS report screenshots are full compositor evidence and
    may contain non-target app windows. The target snapshot remained scoped to
    PersonaChess.
  - `ui screen`, text query, and button query did not expose `Open menu`,
    `Share`, or piece semantics. The visible spatial content is not represented
    as actionable text/button nodes in the default snapshot.
  - `ui tree --view` exposed `UIApplication`, `UIWindowScene`, `UIWindow`, and
    root `_UIHostingView<ModifiedContent<AnyView, RootModifier>>`; deeper
    toolbar/ornament nodes were mostly hidden zero-height implementation nodes.
  - `ui hit-test --point 435,435` on the board and `--point 735,820` near the
    toolbar both returned the root hosting view with a normal SwiftUI hosting
    responder chain.
  - `act tap --backend runtime --ref n6` failed with
    `unsupported_activation_target` because the root hosting view is not a
    `UIControl`. Artifact:
    `/tmp/loupe-personachess-runtime-root-tap-trace`.
  - Native/auto coordinate tap on the visible `Open menu` area and drag on a
    visible piece produced trace diffs, but those diffs were limited to
    zero-height hidden toolbar/ornament nodes and the screenshots did not prove
    a menu opening or a board move. Artifacts:
    `/tmp/loupe-personachess-open-menu-trace`,
    `/tmp/loupe-personachess-board-drag-trace`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same boundary on port `28759`. It captured artifacts at
    `/tmp/loupe-personachess-vision-blind-20260605-043322`, confirmed
    `Open menu`, `Share`, and `--role button` queries all returned empty
    results, and hit-tested both board and toolbar points as the root hosting
    view. Runtime tap on `n6` failed with `unsupported_activation_target`.
    Coordinate tap and drag traces reached an `after` phase, but the before,
    after-tap, and after-drag screenshots had the same SHA-256 hash:
    `c64b414d0227abb2ba20590dc27fe876cd46dd69d069d72f24cca63df7f75342`.
- General fixes produced:
  - VisionOS guidance now treats full screenshots as compositor-level evidence
    that can include other app windows; agents must bind conclusions back to
    the target snapshot/runtime identity.
  - For RealityKit/spatial boards, screenshot-visible objects are not enough to
    claim query/action support. Use app-authored probes, logs, defaults, or
    explicit game-state evidence when pieces or board state matter.
  - Trace diffs containing only hidden zero-height ornament nodes are input
    noise unless a fresh screenshot/report proves a user-visible state change.

### OpenImmersive Vision

- Repo: https://github.com/acuteimmersive/openimmersive
- Revision: `174fb8366797a60654614608732c09d2e6f7eaad`
- Platform: visionOS SwiftUI with an OpenImmersive spatial video player shell
- UI: Vision Pro video-player start window with logo, selected video metadata,
  play control, gallery/file/stream buttons, format options, and a full room
  compositor background.
- Why it matters: this is a real Vision Pro app with a small codebase and
  production-shaped controls. It exposed the difference between screenshot
  evidence, SwiftUI accessibility metadata, notification probes, and actual
  runtime activation.
- Build command:
  `xcodebuild -project OpenImmersive.xcodeproj -scheme OpenImmersiveApp -destination 'generic/platform=visionOS Simulator' -configuration Debug -derivedDataPath /tmp/loupe-build-openimmersive-vision CODE_SIGNING_ALLOWED=NO DEVELOPMENT_TEAM= build`
- Bundle ID: `com.acuteimmersive.openimmersive`
- Launch command:
  `LOUPE_INJECTOR_PATH=/Users/woody/Library/Developer/Xcode/DerivedData/loupe-ettcvsridzgyxrfviwliwteylspr/Build/Products/Debug-xrsimulator/PackageFrameworks/LoupeInjector.framework/LoupeInjector ./.build/debug/loupe app launch --bundle-id com.acuteimmersive.openimmersive --device 40ABB5AB-E81B-4636-BACB-DCE10E5CC049 --inject --port 28805 --timeout 30`
- Evidence:
  - The unmodified app built and launched on Apple Vision Pro Simulator with
    Loupe at `http://127.0.0.1:28805`. Initial report artifacts:
    `/tmp/loupe-openimmersive-report-initial`.
  - The screenshot showed the real OpenImmersive start UI, but compact output
    had `visibleTexts: 0`, `ui query --exact-text 'OpenImmersive'` returned
    `[]`, and `ui query --role button` returned `[]`. The accessibility tree
    contained only window/root entries.
  - `ui tree --view` still exposed useful geometry: the four visible controls
    appeared as SwiftUI drawing/portal host regions around the expected button
    row. `ui hit-test --point 589,613` hit `CGDrawingView` with a responder
    chain through the button-sized host region.
  - Coordinate/native taps produced trace diffs, but fresh screenshots did not
    prove that the stream URL sheet opened. Runtime tap on the host view failed
    with `unsupported_activation_target`.
  - Adding normal SwiftUI `.accessibilityIdentifier(...)` to the controls and
    rebuilding did not make `ui query --test-id` or text queries find them on
    visionOS. This is an important practical boundary: SwiftUI metadata can be
    visible to the app but absent from the UIKit-style Loupe runtime tree.
  - Adding a no-import local `dev.loupe.probe` helper initially registered no
    queryable nodes because registered probes were only used by the watchOS
    snapshot builder. After the Loupe fix below, the same app produced
    queryable synthetic probe nodes. Artifacts:
    `/tmp/loupe-openimmersive-report-after-probe-merge` and
    `/tmp/loupe-openimmersive-report-after-audit-fix`.
  - After the fix, `ui query --test-id openimmersive.enterStreamURL` returned
    `n70`, role `button`, text `Enter Stream URL`, and
    `ui query --role button` returned all four probe-backed controls:
    `openGallery`, `openFiles`, `enterStreamURL`, and `formatOptions`.
  - Runtime tap on the probe correctly failed with
    `unsupported_target` because the matched node is synthetic and not backed by
    a UIView. Treat probes as stable evidence and locators, not proof that
    runtime activation is possible.
  - Current revalidation on port `28812` used an external-only no-import
    overlay helper in `SourcesList.swift`: a clear `UIViewRepresentable`
    backing view carries the same `accessibilityIdentifier`, label, and button
    trait while the notification probe still publishes semantic metadata.
    Artifacts:
    `/tmp/loupe-openimmersive-overlay-report`,
    `/tmp/loupe-openimmersive-overlay-enter-testid-native-fixed`, and
    `/tmp/loupe-openimmersive-overlay-after-enter-fixed`.
  - The view-backed overlay produced two matches for
    `openimmersive.enterStreamURL`: synthetic `LoupeRegisteredProbe` `n82` at
    `725.5,526,207.5,44` and platform-backed `LoupeFallbackFrameView` `n59` at
    `485.5,591,207.5,44`. `ui hit-test --point 590,613` confirmed the latter
    was the action-grade frame through the real button host chain.
  - After the Loupe ordering fix below, `ui query --test-id
    openimmersive.enterStreamURL` prefers the platform-backed `n59` target over
    the synthetic probe, and native `act tap --test-id
    openimmersive.enterStreamURL` no longer fails on duplicate accessibility
    nodes. Its trace target used `sourceRef: n59` and frame
    `485.5,591,207.5,44`.
  - Blind validation with only the Loupe skill and target contract reproduced
    the same result on port `28813`. Artifacts:
    `/tmp/loupe-openimmersive-blind-vision-overlay-report`,
    `/tmp/loupe-openimmersive-blind-vision-hit-test-590-613.json`,
    `/tmp/loupe-openimmersive-blind-vision-enter-tap`,
    `/tmp/loupe-openimmersive-blind-vision-after-report`,
    `/tmp/loupe-openimmersive-blind-vision-enter-runtime-n59`, and
    `/tmp/loupe-openimmersive-blind-vision-enter-runtime-n82`.
  - Revalidation after the runtime target-resolution fix on port `28814`
    confirmed that runtime `act tap --backend runtime --test-id
    openimmersive.enterStreamURL` now targets `ax-n59`/`sourceRef: n59` instead
    of failing with `ambiguous_selector`. The trace still fails with
    `unsupported_activation_target` because `LoupeFallbackFrameView` is not a
    `UIControl`, which is the correct bounded failure for the current runtime
    activation backend. Artifacts:
    `/tmp/loupe-openimmersive-runtime-fix-report`,
    `/tmp/loupe-openimmersive-runtime-testid-after-server-fix`,
    `/tmp/loupe-openimmersive-native-after-server-fix`, and
    `/tmp/loupe-openimmersive-after-native-server-fix`.
  - Even with the corrected action target, native tap/press traces did not open
    the stream URL sheet or format popover in the visionOS Simulator. Fresh
    screenshots stayed on the start screen, so this run proves target selection,
    not end-to-end control activation. This is not evidence that visionOS action
    support is impossible; it means Loupe still needs a visionOS-specific input
    or activation backend beyond the current iOS-style touch HID and UIControl
    runtime activation paths.
- General fixes produced:
  - UIKit/AppKit/visionOS snapshots now merge `LoupeRuntime` registered probes
    as synthetic `LoupeRegisteredProbe` nodes, so injected/no-import
    notification probes are queryable outside watchOS too.
  - Layout audit now ignores Loupe probe containment noise. Probe frames can be
    app-authored evidence in a different coordinate context, especially on
    visionOS, and should not be reported as app layout defects.
  - Skill guidance should state that `.accessibilityIdentifier` alone is not
    enough for some visionOS SwiftUI drawing surfaces. Prefer a real
    `UIViewRepresentable` probe when frame/action accuracy matters; use
    notification probes for zero-dependency structural evidence, and prove
    actions separately with hit-test, trace, and fresh screenshots.
  - `ui query` and action target resolution now prefer platform-backed nodes
    over synthetic registered probes when the same semantic test ID appears in
    both. This keeps local no-import overlay probes usable without making
    duplicate synthetic notification nodes break `act tap --test-id`.
  - Runtime activation and mutation endpoints use the same platform-backed
    preference before enforcing single-target selection, so duplicate
    overlay-plus-notification probes fail on the real capability boundary
    instead of `ambiguous_selector`.

## iOS SwiftUI Candidates

1. https://github.com/Dimillian/IceCubesApp
   - Flow: account-add, server search, notification alert, timeline shell.
   - Loupe focus: SwiftUI text capture, system alert boundary, list hit-test.
   - Risk: requires xcconfig and may need network.
2. https://github.com/rafsoh/dimeApp
   - Flow: expense list, add/edit transaction, chart or summary panels.
   - Loupe focus: SwiftUI forms, local persistence, text entry, mutation probes.
   - Risk: app data setup may matter.
   - First pass: verified as a seed case after an external-only CloudKit bypass.
     The useful loop is screenshot-only onboarding text, coordinate category
     selection, SwiftUI list host mutation, and empty reflect candidates.
3. https://github.com/pencilresearch/OpenScanner
   - Flow: onboarding, document list, camera/import surfaces where available.
   - Loupe focus: permission prompts, empty states, image-heavy UI.
   - First pass: verified as a seed case above. The useful loop is floating
     search focus/type/mutation; simulator camera paths may still limit action
     depth.
4. https://github.com/rrroyal/Harbour
   - Flow: connection setup, server list, container detail.
   - Loupe focus: settings forms, networking diagnostics, state flags.
   - Risk: may need a Docker/Portainer endpoint for deep routes.
   - First pass: verified onboarding -> setup form via injection. Useful loop is
     screenshot/hit-test for onboarding, role-query text fields, dummy typing,
     mutation, and reflect triage; deep server/container routes still need a
     Portainer fixture.
5. https://github.com/azooKey/azooKey
   - Flow: settings app, keyboard configuration, extension surfaces.
   - Loupe focus: extension boundaries, text input, accessibility selectors.
   - Risk: keyboard extension setup can dominate the loop.
6. https://github.com/brittanyarima/Steps
   - Flow: step summary, goals tab, bottom sheet goal creation, persisted list.
   - Loupe focus: screenshot-only SwiftUI rows/buttons, text entry, row
     mutation, widget bundle-ID setup.
   - Risk: HealthKit/widget setup and dependency drift can dominate builds.
7. https://github.com/isaced/V2exOS
   - Flow: topic tabs, paged SwiftUI lists, detail presentation.
   - Loupe focus: screenshot-rich but query-sparse SwiftUI lists, hit-test
     driven row actions, tab changes, and visual mutation bounds.
   - Risk: network content can vary.

## iOS UIKit Candidates

1. https://github.com/DeluxeAlonso/UpcomingMovies
   - Flow: movie list, detail, search or favorites.
   - Loupe focus: UIKit navigation, table/collection views, TMDB-backed lists.
   - Risk: API/network fixture may be needed.
2. https://github.com/dheerajghub/SwiggyClone
   - Flow: home list, compositional layout sections, detail/cart shell.
   - Loupe focus: UICollectionView compositional layout, self-sizing behavior.
   - Risk: clone UI may be less production-like than the others.
3. https://github.com/MessageKit/MessageKit
   - Flow: example picker, chat thread, input bar, send message.
   - Loupe focus: chat collection cells, input accessory text view, source
     reflection into reusable message cells.
   - Risk: example data is dynamic and can drift between captures.
4. https://github.com/abdorizak/Expense-Tracker-App
   - Flow: add expense, list update, summary.
   - Loupe focus: UIKit forms and source reflection from simple state changes.
   - Risk: smaller app; useful as a quick UIKit sanity pass.
5. https://github.com/aydenp/Bank
   - Flow: accounts, transaction list, detail.
   - Loupe focus: list/detail navigation and fixture-driven state.
   - Risk: Plaid/API setup may need stubbing.
6. https://github.com/gahntpo/CoordinatorProject
   - Flow: coordinator navigation across UIKit and SwiftUI screens.
   - Loupe focus: mixed framework boundaries and route traces.
   - Risk: architecture sample rather than full consumer app.

## macOS AppKit Candidates

1. https://github.com/CodeEditApp/CodeEdit
   - Flow: welcome window, open project, source editor, preferences.
   - Loupe focus: AppKit windows, source editor text views, split views.
   - Risk: large build and local file fixtures.
2. https://github.com/TableProApp/TablePro
   - Flow: connection window, sidebar, SQL editor, result table.
   - Loupe focus: tables, outlines, split views, editor panes.
   - Risk: database fixture needed for deep validation.
3. https://github.com/Schlaubischlump/LocationSimulator
   - Flow: device selection, map/location mutation, simulator integration.
   - Loupe focus: AppKit controls plus external simulator state.
   - Risk: external device services may complicate isolation.
4. https://github.com/rlxone/Equinox
   - Flow: image import, dynamic wallpaper editor, export.
   - Loupe focus: document workflow, image views, toolbar actions.
   - Risk: file fixtures needed.
5. https://github.com/migueldeicaza/SwiftTerm
   - Flow: terminal view, keyboard input, scrollback.
   - Loupe focus: AppKit text/scroll performance and input traces.
   - Risk: library/demo shape must be checked before treating as an app.

## macOS SwiftUI Candidates

1. https://github.com/jordanbaird/Ice
   - Flow: menu bar item, settings windows, menu item visibility controls.
   - Loupe focus: menu bar app surfaces and SwiftUI settings.
   - Risk: menu bar/system UI boundaries.
2. https://github.com/mrkai77/Loop
   - Flow: onboarding, radial menu, settings, URL scheme actions.
   - Loupe focus: overlays, global shortcuts, geometry changes.
   - Risk: accessibility permissions and global event hooks.
3. https://github.com/sindresorhus/Gifski
   - Flow: import video, conversion settings, progress, export.
   - Loupe focus: file dialogs, progress state, SwiftUI/AppKit integration.
   - Risk: media fixture and long-running conversion.
4. https://github.com/milanvarady/Applite
   - Flow: Homebrew package list, search, install/update details.
   - Loupe focus: search, lists, network/process logs, mutation reflect.
   - Risk: Homebrew side effects; use dry or read-only paths.
5. https://github.com/buresdv/Cork
   - Flow: formula/cask list, search, detail, updates.
   - Loupe focus: large SwiftUI lists and state refresh.
   - Risk: Homebrew side effects; use read-only scenarios first.
6. https://github.com/yattee/yattee
   - Flow: default main window, sidebar list, player/settings surfaces.
   - Loupe focus: sparse SwiftUI semantics, AppKit bridge lists, mutation
     reflect, and bounded macOS row activation.
   - Risk: media/network flows need service setup; use read-only default-window
     scenarios first.

## tvOS Candidates

1. https://github.com/yattee/yattee
   - Flow: home/browse, focus movement, video detail.
   - Loupe focus: tvOS focus tree, remote press traces, media grid.
   - Risk: service configuration may be required.
2. https://github.com/dkhamsing/news
   - Flow: category tabs, article list, focus movement.
   - Loupe focus: UIKit tvOS tab selection, table rows, remote press traces.
   - Risk: network content can vary.
3. https://github.com/isaced/V2exOS
   - Flow: topic list, detail, navigation/sidebar.
   - Loupe focus: SwiftUI tvOS lists and remote navigation.
   - Risk: network content can vary.
4. https://github.com/eggerco/cronica
   - Flow: watchlist, movie detail, search.
   - Loupe focus: multiplatform SwiftUI across tvOS/watchOS/visionOS.
   - Risk: TMDB/API configuration.
5. https://github.com/alfianlosari/ChatGPTSwiftUI
   - Flow: chat list, prompt entry, settings.
   - Loupe focus: tvOS text entry and remote actions.
   - Risk: API key required; use mocked/offline surfaces first.
6. https://github.com/michaeldvinci/swiftshelf-tvos
   - Flow: server setup, audiobook library, player.
   - Loupe focus: tvOS forms and focus movement.
   - Risk: self-hosted backend fixture needed.

## watchOS Candidates

1. https://github.com/eggerco/cronica
   - Flow: watchlist and item detail.
   - Loupe focus: registered probes, accessibility export, compact screens.
   - Risk: shared data/API setup.
2. https://github.com/open-trackers/Gym-Routine-Tracker-Watch-App
   - Flow: workout list, timer/session detail.
   - Loupe focus: independent watchOS SwiftUI app, probe bounds, logs/defaults.
   - Risk: CloudKit/signing setup and no-import probe instrumentation.
3. https://github.com/silsha/pwnagotchi.app
   - Flow: device status, companion summary.
   - Loupe focus: watchOS plus iOS/macOS companion surfaces.
   - Risk: external hardware/service assumptions.
4. https://github.com/BastiaanJansen/brush
   - Flow: toothbrush timer, HealthKit save path.
   - Loupe focus: watchOS timers and permission prompts.
   - Risk: older project and HealthKit permissions.
5. https://github.com/superturboryan/Magic-Tap
   - Flow: watch-to-phone control setup.
   - Loupe focus: WatchConnectivity and paired-device state.
   - First pass: first-launch watch setup works with no-import probes; the
     companion app needs a small external dependency-drift no-op patch.
   - Risk: cross-device coupling for phone-control behavior.

## visionOS Candidates

1. https://github.com/Dimillian/IceCubesApp
   - Flow: account-add and app shell on visionOS.
   - Loupe focus: SwiftUI visionOS build compatibility and window snapshots.
   - First pass: scheme advertises visionOS, but the current build failed on
     multiple app-side SDK compatibility issues (`glassEffect`,
     `navigationTransition`, `Assistant`, editor/media picker availability).
     Treat it as an iOS SwiftUI validation app for now, not a low-friction
     visionOS runtime target.
2. https://github.com/acuteimmersive/openimmersive
   - Flow: start window, source buttons, format options, stream URL setup.
   - Loupe focus: visionOS screenshot vs structure, SwiftUI drawing surfaces,
     accessibilityIdentifier limits, no-import notification probes.
   - Risk: controls still require screenshot/hit-test proof for actions; the
     probe-backed nodes are synthetic locators.
3. https://github.com/alvr-org/alvr-visionos
   - Flow: connection/setup screens before streaming.
   - Loupe focus: visionOS app lifecycle and spatial UI host views.
   - Risk: streaming backend and entitlements.
4. https://github.com/eggerco/cronica
   - Flow: watchlist/search/detail.
   - Loupe focus: one app across tvOS/watchOS/visionOS.
   - Risk: API setup.
5. https://github.com/FlipByBlink/HandsRuler
   - Flow: hand-measurement UI and permission prompts.
   - Loupe focus: RealityKit/AR permission boundaries.
   - Risk: simulator may not expose meaningful hand tracking; validated seed
     shows observe/report works, while Start action proof is not automatic.
6. https://github.com/FlipByBlink/PersonaChess
   - Flow: chess board and SharePlay setup surfaces.
   - Loupe focus: spatial controls and board state.
   - Risk: SharePlay/multiplayer setup; validated seed shows observe/report
     works, but default query/action surfaces do not expose board state.

## First-Pass Findings To Feed Back

- Real SwiftUI apps can expose meaningful UIKit host structure, but visible
  app text may appear in screenshot before it is well represented in the app
  view/accessibility tree.
- System alerts are outside the app runtime server. Treat them as screenshot
  and host/simulator problems, not `ui query` problems. Verify with a fresh
  screenshot because an app-side action trace may still show only the covered
  app content changing. If a coordinate action returns success but the
  screenshot still shows the alert, record the action as not proven rather than
  as a successful dismissal.
- When testing the Loupe working tree, always rebuild and set the local injector
  path, and run the repo-local `./.build/debug/loupe`. A stale global CLI or
  injector can produce old command help, missing routes, or older snapshot
  schemas.
- A successful action command is not enough. Keep before/after traces, then
  run fresh `ui report` and `ui hit-test` where geometry or overlays matter.
- Saved snapshot refs are not stable live object identifiers. For ref-based
  `ui set` from a saved report or trace, pass `--snapshot <snapshot.json>` so
  the CLI can map the saved node to the current live runtime ref before
  mutating.
- Paged carousels and self-updating list cells can produce noisy trace diffs.
  Verify the current page with fresh compact/screen/accessibility output and
  scroll or page state rather than treating raw appeared/disappeared trace
  entries as the only truth.
- Secure text fields should stay redacted in snapshots, compact output,
  accessibility trees, and action trace metadata. Never use a real password or
  secret as validation input. Do not require a `secureTextField` role; prove
  secure input with node metadata such as `uiKit.textField.isSecureTextEntry`
  plus redacted text/value evidence.
- SwiftUI-heavy apps can make `ui audit` noisy because UIKit host controls and
  private text-selection views are visible to the runtime. Triage audit output
  by source, role, frame, and screenshot context before feeding it back as an
  application issue.
- Do not infer shared CLI flags across grouped commands. For example,
  `ui audit` does not accept `--limit`; check current subcommand help before
  adding convenience flags to blind-agent contracts.
- iOS SwiftUI pager/list apps can show real topic titles and tab labels in the
  screenshot while compact `visibleTexts` and text queries are empty. Use
  default role queries for current cells, hit-test/responder-chain evidence for
  geometry, and fresh screenshots/traces for route or tab changes.
- SwiftUI onboarding and presentation surfaces can show visible text and CTAs
  in screenshots while compact/text queries are empty and the underlying tab or
  list shell still appears in the view tree. Use current-surface query,
  hit-test, coordinate/ref action traces, and fresh screenshots before calling
  a modal label queryable or a background node visible.
- `act type` writes into the current input selection. In real forms, focusing a
  field can select the existing value, so the next type command may replace
  rather than append. Trace metadata redacts requested text, so verify the
  resulting value with a fresh report/query/node.
- `debug network` is development evidence from app-authored
  `dev.loupe.network` events or LoupeKit fixture URLProtocol hooks, not a
  general sniffer for arbitrary app traffic. Empty output on a real network app
  is a bounded diagnostic result.
- `ui reflect` source candidates are ranked hints, not patch instructions. A
  non-empty candidate can still be weak for SwiftUI-generated navigation titles
  or platform host labels; compare the candidate file against the observed
  hierarchy before feeding it back.
- tvOS SwiftUI apps can expose useful UIKit-backed view/focus structure even
  when compact semantic text is sparse. Use `act press` traces and fresh
  screenshots to prove focus movement or selection. Treat scroll-container
  content size and focus highlight expansion as normal platform behavior unless
  the screenshot or effective state shows a real layout bug.
- watchOS inject-only runtimes can start Loupe and report screen metadata, but
  there is no general UIKit/AppKit view-tree walker. For real SwiftUI watch
  screens, add public `.loupeProbe(...)` or a no-import local notification
  helper on the regions the agent should reason about. Nested probe frames are
  represented as parent/child nodes. Keep probes sparse and actionable; if broad
  parent probes overlap child probes, default current-surface query may hide the
  child, so diagnose with `--include-hidden` or adjust placement. SwiftUI
  sheets and ScrollViews can also leave useful probes offscreen or behind the
  screenshot-visible workflow; prove current visibility with `ui screen`,
  default query, and fresh screenshots before tapping. Prefer native/auto
  coordinate actions on the watch simulator; do not ask a blind agent to prove
  watchOS navigation with `--backend runtime` alone. On first launch of real
  watchOS apps, use `app info` plus a generous first `ui report --timeout`
  before declaring the runtime dead. After sheet dismissal or navigation,
  recapture after a short wait because registered probes can lag the screenshot
  for one report.
- visionOS injection can observe real SwiftUI/RealityKit apps on the simulator,
  but the report snapshot uses app-window coordinates while screenshots show
  the full spatial compositor, including other app windows that may still be
  open. Visible SwiftUI text can be rendered into drawing views and be absent
  from text queries. RealityKit/spatial objects can be visible in the screenshot
  without actionable view/accessibility nodes. Use screenshots plus hit-test,
  responder-chain, geometry, probes, logs, defaults, or app/game-state evidence
  before claiming spatial action success. External visionOS apps still need
  installation through `xcrun simctl install`; `loupe app launch`
  attaches/launches but is not an app installer.
