import Foundation
import LoupeCLIModel
import LoupeCore

struct AccessibilityOptions {
    var snapshotURL: URL
    var includeHidden: Bool
    var outputURL: URL?

    init(_ arguments: [String]) throws {
        guard let path = arguments.first, !path.hasPrefix("--") else {
            throw CLIError("Usage: loupe ui accessibility <snapshot.json> [--include-hidden] [--output <path>]")
        }

        snapshotURL = URL(fileURLWithPath: path)
        includeHidden = false
        outputURL = nil

        var index = 1
        while index < arguments.count {
            switch arguments[index] {
            case "--include-hidden":
                includeHidden = true
            case "--output":
                outputURL = URL(fileURLWithPath: try Self.value(after: "--output", in: arguments, index: &index))
            case "--help", "-h":
                throw CLIError("Usage: loupe ui accessibility <snapshot.json> [--include-hidden] [--output <path>]")
            default:
                throw CLIError("Unknown accessibility option: \(arguments[index])")
            }
            index += 1
        }
    }

    private static func value(after option: String, in arguments: [String], index: inout Int) throws -> String {
        let valueIndex = index + 1
        guard valueIndex < arguments.count else {
            throw CLIError("\(option) requires a value")
        }
        index = valueIndex
        return arguments[valueIndex]
    }
}
