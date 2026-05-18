import Foundation

public enum LoupeRuntimeEventKind: String, Codable, Equatable {
    case touch
    case wait
    case log
}

public enum LoupeTouchPhase: String, Codable, Equatable {
    case began
    case moved
    case ended
    case cancelled
}

public enum LoupeRecordedSelectorKind: String, Codable, Equatable {
    case testID
    case text
    case roleAndText
    case ref
}

public struct LoupeRecordedSelector: Codable, Equatable {
    public var kind: LoupeRecordedSelectorKind
    public var value: String
    public var role: String?
    public var exact: Bool

    public init(
        kind: LoupeRecordedSelectorKind,
        value: String,
        role: String? = nil,
        exact: Bool = true
    ) {
        self.kind = kind
        self.value = value
        self.role = role
        self.exact = exact
    }
}

public struct LoupeRecordedTargetCandidate: Codable, Equatable {
    public var tree: String
    public var selector: LoupeRecordedSelector
    public var ref: String
    public var sourceRef: String?
    public var role: String?
    public var testID: String?
    public var text: String?
    public var frame: LoupeRect?
    public var activationPoint: LoupePoint?
    public var score: Int

    public init(
        tree: String,
        selector: LoupeRecordedSelector,
        ref: String,
        sourceRef: String? = nil,
        role: String? = nil,
        testID: String? = nil,
        text: String? = nil,
        frame: LoupeRect? = nil,
        activationPoint: LoupePoint? = nil,
        score: Int
    ) {
        self.tree = tree
        self.selector = selector
        self.ref = ref
        self.sourceRef = sourceRef
        self.role = role
        self.testID = testID
        self.text = text
        self.frame = frame
        self.activationPoint = activationPoint
        self.score = score
    }
}

public struct LoupeRuntimeEvent: Codable, Equatable {
    public var id: String
    public var kind: LoupeRuntimeEventKind
    public var timestamp: Date
    public var phase: LoupeTouchPhase?
    public var points: [LoupePoint]
    public var targetCandidates: [LoupeRecordedTargetCandidate]
    public var message: String?

    public init(
        id: String = UUID().uuidString,
        kind: LoupeRuntimeEventKind,
        timestamp: Date = Date(),
        phase: LoupeTouchPhase? = nil,
        points: [LoupePoint] = [],
        targetCandidates: [LoupeRecordedTargetCandidate] = [],
        message: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.timestamp = timestamp
        self.phase = phase
        self.points = points
        self.targetCandidates = targetCandidates
        self.message = message
    }
}

public struct LoupeRuntimeLog: Codable, Equatable {
    public var id: String
    public var timestamp: Date
    public var level: String
    public var message: String
    public var metadata: [String: LoupeMetadataValue]

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        level: String,
        message: String,
        metadata: [String: LoupeMetadataValue] = [:]
    ) {
        self.id = id
        self.timestamp = timestamp
        self.level = level
        self.message = message
        self.metadata = metadata
    }
}

public struct LoupeRuntimeIdentity: Codable, Equatable {
    public var launchID: String
    public var startedAt: Date
    public var bundleIdentifier: String?
    public var processIdentifier: Int32
    public var simulatorUDID: String?
    public var simulatorName: String?

    public init(
        launchID: String = UUID().uuidString,
        startedAt: Date = Date(),
        bundleIdentifier: String? = nil,
        processIdentifier: Int32,
        simulatorUDID: String? = nil,
        simulatorName: String? = nil
    ) {
        self.launchID = launchID
        self.startedAt = startedAt
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.simulatorUDID = simulatorUDID
        self.simulatorName = simulatorName
    }
}

public struct LoupeRecording: Codable, Equatable {
    public var id: String
    public var alias: String?
    public var startedAt: Date
    public var endedAt: Date?
    public var appIdentity: LoupeRuntimeIdentity?
    public var events: [LoupeRuntimeEvent]

    public init(
        id: String = UUID().uuidString,
        alias: String? = nil,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        appIdentity: LoupeRuntimeIdentity? = nil,
        events: [LoupeRuntimeEvent] = []
    ) {
        self.id = id
        self.alias = alias
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.appIdentity = appIdentity
        self.events = events
    }
}

public struct LoupeRuntimeState: Codable, Equatable {
    public var identity: LoupeRuntimeIdentity
    public var recording: LoupeRecording?
    public var logs: [LoupeRuntimeLog]

    public init(
        identity: LoupeRuntimeIdentity,
        recording: LoupeRecording? = nil,
        logs: [LoupeRuntimeLog] = []
    ) {
        self.identity = identity
        self.recording = recording
        self.logs = logs
    }
}
