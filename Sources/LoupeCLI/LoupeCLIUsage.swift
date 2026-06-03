extension LoupeCLI {
    static let targetUsage = """
    Usage: loupe target <subcommand>

    SUBCOMMANDS:
      list                    List known runtime targets.
      use                     Select the current runtime target.
      current                 Show the current runtime target.
    """

    static let runtimeUsage = """
    Usage: loupe runtime <subcommand>

    SUBCOMMANDS:
      start                   Launch and inject an app runtime.
      launch                  Launch an app through the platform backend.
      list                    List known injected runtimes.
      use                     Select the current runtime.
      current                 Show the current runtime selection.
      info                    Fetch runtime identity and health.
      logs                    Fetch runtime logs.
      cleanup                 Prune stale runtime records and traces.
    """

    static let observeUsage = """
    Usage: loupe observe <subcommand>

    SUBCOMMANDS:
      capture                 Capture screenshot and runtime structure artifacts.
      tree                    Print view or accessibility trees.
      screen                  Print visible semantic and styled elements.
      screenshot              Save a platform screenshot to a path.
      accessibility           Export an accessibility tree from a snapshot.
      compact                 Compact a full snapshot for agents.
      fetch                   Fetch a raw runtime endpoint.
    """

    static let inspectUsage = """
    Usage: loupe inspect <snapshot.json> (--test-id <id> | --text <text> | --role <role> | --ref <ref>) [--include-hidden] [--node-only|--fields node,parent,children,siblings]

    Grouped aliases:
      loupe inspect node      Inspect one matched node with local context.
      loupe inspect query     Query a snapshot by selector.
      loupe inspect subtree   Print a bounded subtree around a matched node.
      loupe inspect paint     Inspect paint stack ordering at a point or ref.
    """

    static let actUsage = """
    Usage: loupe act <subcommand>

    SUBCOMMANDS:
      tap                     Tap a selector, ref, or coordinate.
      swipe                   Dispatch a one-finger swipe.
      drag                    Dispatch a one-finger drag.
      type                    Type text into the focused field.
      press                   Press a simulator remote or keyboard button.
      wait                    Wait for visible, gone, or value state.
    """

    static let uiUsage = """
    Usage: loupe ui <subcommand>

    SUBCOMMANDS:
      audit                   Audit layout, contrast, and target sizing.
      mutations               List supported runtime UI mutations.
      set                     Mutate one supported UI property.
      set-many                Mutate matching UI properties in a batch.
      constraints             Inspect captured layout constraints.
      set-constraint          Mutate a captured constraint.
      deactivate-constraint   Deactivate a captured constraint.
      compare-design          Compare a snapshot with exported design data.
      hit-test                Inspect the view intercepting a point.
      responder-chain         Inspect responders for a selector.
    """

    static let traceUsage = """
    Usage: loupe trace <subcommand>

    SUBCOMMANDS:
      summary                 Summarize action trace artifacts.
      diff                    Compare before/after snapshots.
      explore                 Probe visible route-like controls.
      cleanup                 Prune stale trace bundles.
    """

    static func commandUsage(_ command: String) -> String? {
        switch command {
        case "target":
            return targetUsage
        case "runtime":
            return runtimeUsage
        case "observe":
            return observeUsage
        case "inspect":
            return inspectUsage
        case "act":
            return actUsage
        case "ui":
            return uiUsage
        case "debug":
            return debugUsage
        case "state":
            return stateUsage
        case "env":
            return envUsage
        case "perf":
            return perfUsage
        case "trace":
            return traceUsage
        case "target list":
            return "Usage: loupe target list [--json] [--timeout <seconds>]"
        case "target use":
            return "Usage: loupe target use <bundle-id> | --bundle-id <id> | --host <url> [--udid <sim>]"
        case "target current":
            return "Usage: loupe target current [--json] [--timeout <seconds>]"
        case "runtime start":
            return "Usage: loupe runtime start --bundle-id <id> [--device <sim>|--udid <sim>] [--port <port>] [--env KEY=VALUE] [--timeout <seconds>]"
        case "runtime launch":
            return "Usage: loupe runtime launch --bundle-id <id> [--device <sim>|--udid <sim>] [--inject] [--dylib <path>] [--env KEY=VALUE] [--timeout <seconds>]"
        case "runtime list":
            return "Usage: loupe runtime list [--json] [--timeout <seconds>]"
        case "runtime use":
            return "Usage: loupe runtime use <bundle-id> | --bundle-id <id> | --host <url> [--udid <sim>]"
        case "runtime current":
            return "Usage: loupe runtime current [--json] [--timeout <seconds>]"
        case "runtime info":
            return "Usage: loupe runtime info [--host <url>] [--udid <sim>] [--output <path>]"
        case "runtime logs":
            return "Usage: loupe runtime logs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "observe capture", "observe capture-report":
            return "Usage: loupe observe capture [--host <url>] [--udid <sim>] [--bundle-id <id>] --output <dir> [--screen-map-limit <n>] [--timeout <seconds>]"
        case "observe tree":
            return """
            Usage: loupe observe tree [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--view|--accessibility] [--depth <n>]
                   loupe observe tree --interesting|--visible-leaves|--text|--mutable

            Print a human-readable tree. Use --mutable to discover refs likely useful for runtime mutation.
            """
        case "observe text", "observe text-map":
            return "Usage: loupe observe text [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--accessibility]"
        case "observe screen", "observe screen-map":
            return "Usage: loupe observe screen [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--include-hidden] [--include-containers] [--limit <n>]"
        case "observe screenshot":
            return "Usage: loupe observe screenshot --udid <sim> --output <path> [--timeout <seconds>]"
        case "inspect node":
            return "Usage: loupe inspect node <snapshot.json> (--test-id <id> | --text <text> | --role <role> | --ref <ref>) [--include-hidden] [--fields node,parent,children,siblings]"
        case "inspect query":
            return "Usage: loupe inspect query [snapshot.json] (--test-id <id> | --text <text> | --role <role> | --ref <ref>) [--host <url>] [--bundle-id <id>] [--tree view|accessibility]"
        case "inspect subtree":
            return "Usage: loupe inspect subtree <snapshot.json> (--test-id <id> | --text <text> | --role <role> | --ref <ref>) [--depth <n>] [--include-hidden]"
        case "inspect paint", "inspect paint-stack":
            return "Usage: loupe inspect paint [snapshot.json] (--point x,y | --ref <ref>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--limit <n>] [--json]"
        case "act tap":
            return "Usage: loupe act tap (--test-id <id> | --ref <ref> | --x <n> --y <n>) --udid <sim> [--host <url>] [--snapshot <snapshot.json>] [--trace-dir <path>] [--expect-visible <testID>]"
        case "act swipe":
            return "Usage: loupe act swipe --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--no-verify-scroll] [--trace-dir <path>]"
        case "act drag":
            return "Usage: loupe act drag --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--trace-dir <path>]"
        case "act type":
            return "Usage: loupe act type <text> --udid <sim> [--host <url>] [--trace-dir <path>]"
        case "act press":
            return "Usage: loupe act press up|down|left|right|select|menu|playPause --udid <sim> [--host <url>] [--trace-dir <path>] [--expect-visible <testID>]"
        case "act wait":
            return "Usage: loupe act wait visible|gone|value <selector> [--host <url>] [--udid <sim>] [--bundle-id <id>] [--timeout <seconds>]"
        case "ui audit":
            return AuditOptions.usage.replacingOccurrences(of: "loupe audit", with: "loupe ui audit")
        case "ui mutations":
            return "Usage: loupe ui mutations [--host <url>] [--udid <sim>] [--bundle-id <id>]"
        case "ui set":
            return MutationSetOptions.usage.replacingOccurrences(of: "loupe set", with: "loupe ui set")
        case "ui set-many":
            return BatchMutationOptions.usage.replacingOccurrences(of: "loupe set-many", with: "loupe ui set-many")
        case "ui constraints":
            return ConstraintListOptions.usage.replacingOccurrences(of: "loupe constraints", with: "loupe ui constraints")
        case "ui set-constraint":
            return ConstraintMutationOptions.usage(deactivate: false).replacingOccurrences(of: "loupe set-constraint", with: "loupe ui set-constraint")
        case "ui deactivate-constraint":
            return ConstraintMutationOptions.usage(deactivate: true).replacingOccurrences(of: "loupe deactivate-constraint", with: "loupe ui deactivate-constraint")
        case "ui reflect":
            return "Usage: loupe ui reflect <mutation-response.json> --source <dir> [--output <path>]"
        case "ui compare-design":
            return "Usage: loupe ui compare-design <snapshot.json> <design.json> [--json] [--limit <n>]"
        case "ui hit-test":
            return "Usage: loupe ui hit-test --point x,y [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "ui responder-chain":
            return "Usage: loupe ui responder-chain (--test-id <id> | --ref <ref> | --text <text> | --role <role>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "debug console":
            return "Usage: loupe debug console [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "debug network":
            return "Usage: loupe debug network [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "debug refs":
            return "Usage: loupe debug refs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "debug object-graph":
            return "Usage: loupe debug object-graph [target|--target <name>] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "debug heap":
            return "Usage: loupe debug heap [target|--target <name>] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "state defaults":
            return "Usage: loupe state defaults get|set|unset <key> [value] [--bool true|false] [--number n] [--host <url>] [--output <path>]"
        case "state flags":
            return "Usage: loupe state flags get|set|unset <key> [value] [--bool true|false] [--number n] [--host <url>] [--output <path>]"
        case "state keychain":
            return "Usage: loupe state keychain list [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "env appearance":
            return "Usage: loupe env appearance [light|dark|system] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "perf scroll":
            return """
            Usage: loupe perf scroll --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--trace-dir <path>] [--output <path>]
                   loupe perf scroll (--test-id <id>|--ref <ref>|--text <text>|--role <role>) (--delta dx,dy|--to-offset x,y) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]
            """
        case "trace summary":
            return "Usage: loupe trace summary <trace-dir> [--json] [--limit <n>]"
        case "trace diff":
            return "Usage: loupe trace diff <before-snapshot.json> <after-snapshot.json> [--json] [--changed-only] [--limit <n>]"
        case "trace explore":
            return "Usage: loupe trace explore [--host <url>] [--udid <sim>] [--bundle-id <id>] [--limit <n>] [--settle <seconds>] [--back-point x,y] [--trace-dir <dir>] [--output <path>] [--json]"
        case "start":
            return """
            Usage: loupe start --bundle-id <id> [--device <sim>|--udid <sim>] [--port <port>] [--env KEY=VALUE] [--timeout <seconds>]

            Launch and inject an Apple simulator app so the in-app Loupe runtime starts.
            --device and --udid accept a simulator UDID, simulator name, or booted.
            """
        case "launch":
            return """
            Usage: loupe launch --bundle-id <id> [--device <sim>|--udid <sim>] [--inject] [--dylib <path>] [--env KEY=VALUE] [--timeout <seconds>]

            Launch an Apple simulator app through simctl. Use --inject to auto-resolve LoupeInjector when the platform supports injection.
            """
        case "set-many":
            return BatchMutationOptions.usage
        case "set", "mutate":
            return MutationSetOptions.usage
        case "capture-report":
            return "Usage: loupe capture-report [--host <url>] [--udid <sim>] [--bundle-id <id>] --output <dir> [--screen-map-limit <n>] [--timeout <seconds>]"
        case "logs":
            return "Usage: loupe logs [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>]"
        case "diff":
            return "Usage: loupe diff <before-snapshot.json> <after-snapshot.json> [--json] [--changed-only] [--limit <n>]"
        case "explore-routes":
            return "Usage: loupe explore-routes [--host <url>] [--udid <sim>] [--bundle-id <id>] [--limit <n>] [--settle <seconds>] [--back-point x,y] [--trace-dir <dir>] [--output <path>] [--json]"
        case "trace-summary":
            return "Usage: loupe trace-summary <trace-dir> [--json] [--limit <n>]"
        case "tap":
            return "Usage: loupe tap (--test-id <id> | --ref <ref> | --x <n> --y <n>) --udid <sim> [--host <url>] [--snapshot <snapshot.json>] [--trace-dir <path>] [--expect-visible <testID>]"
        case "swipe":
            return "Usage: loupe swipe --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--no-verify-scroll] [--trace-dir <path>]"
        case "drag":
            return "Usage: loupe drag --from x,y --to x,y --udid <sim> [--host <url>] [--duration <seconds>] [--trace-dir <path>]"
        case "type":
            return "Usage: loupe type <text> --udid <sim> [--host <url>] [--trace-dir <path>]"
        case "press":
            return "Usage: loupe press up|down|left|right|select|menu|playPause --udid <sim> [--host <url>] [--trace-dir <path>] [--expect-visible <testID>]"
        case "wait-for-visible":
            return "Usage: loupe wait-for-visible (--test-id <id> | --ref <ref> | --text <text> | --role <role>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>] [--timeout <seconds>]"
        case "wait-for-gone":
            return "Usage: loupe wait-for-gone (--test-id <id> | --ref <ref> | --text <text> | --role <role>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--timeout <seconds>]"
        case "wait-for-value":
            return "Usage: loupe wait-for-value (--test-id <id> | --ref <ref>) --key <path> --equals <value> [--host <url>] [--udid <sim>] [--bundle-id <id>] [--output <path>] [--timeout <seconds>]"
        case "tree":
            return """
            Usage: loupe tree [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--view|--accessibility] [--depth <n>]
                   loupe tree --interesting|--visible-leaves|--text|--mutable

            Print a human-readable tree. Use --mutable to discover refs likely useful for runtime mutation.
            """
        case "text-map":
            return "Usage: loupe text-map [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--accessibility]"
        case "screen-map":
            return "Usage: loupe screen-map [snapshot.json] [--host <url>] [--udid <sim>] [--bundle-id <id>] [--include-hidden] [--include-containers] [--limit <n>]"
        case "runtimes", "apps":
            return "Usage: loupe runtimes [--json] [--timeout <seconds>]"
        case "mutations":
            return """
            Usage: loupe mutations [--host <url>] [--udid <sim>] [--bundle-id <id>]
                   loupe mutations (--ref <ref> | --text <text> | --test-id <id>)

            List runtime mutation capabilities globally or for one matched node.
            """
        case "constraints":
            return ConstraintListOptions.usage
        case "set-constraint":
            return ConstraintMutationOptions.usage(deactivate: false)
        case "deactivate-constraint":
            return ConstraintMutationOptions.usage(deactivate: true)
        case "paint-stack":
            return "Usage: loupe paint-stack [snapshot.json] (--point x,y | --ref <ref>) [--host <url>] [--udid <sim>] [--bundle-id <id>] [--limit <n>] [--json]"
        case "screenshot":
            return "Usage: loupe screenshot --udid <sim> --output <path> [--timeout <seconds>]"
        case "cleanup":
            return "Usage: loupe cleanup [--dry-run] [--no-runtimes] [--no-traces] [--traces-older-than <duration>|--all-traces] [--timeout <seconds>]"
        case "current":
            return "Usage: loupe current [--json] [--timeout <seconds>]"
        case "version", "--version":
            return "Usage: loupe version\n       loupe --version"
        default:
            return nil
        }
    }
}
