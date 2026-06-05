import Foundation
import Testing
@testable import LoupeCLI

struct OfflineUIOutputOptionsTests {
    @Test func compactSnapshotModeAcceptsOutputPath() throws {
        let options = try CompactOptions([
            "/tmp/loupe-snapshot.json",
            "--output", "/tmp/loupe-compact.json",
        ])

        #expect(options.snapshotURL.path == "/tmp/loupe-snapshot.json")
        #expect(options.outputURL?.path == "/tmp/loupe-compact.json")
    }

    @Test func compactSnapshotModeAcceptsRuntimeSelectionOptionsFromHelp() throws {
        let options = try CompactOptions([
            "/tmp/loupe-snapshot.json",
            "--host", "http://127.0.0.1:28823",
            "--udid", "SIM-UDID",
            "--bundle-id", "com.example.App",
            "--timeout", "10",
        ])

        #expect(options.snapshotURL.path == "/tmp/loupe-snapshot.json")
        #expect(options.host.absoluteString == "http://127.0.0.1:28823")
        #expect(options.hostWasExplicit)
        #expect(options.udid == "SIM-UDID")
        #expect(options.bundleID == "com.example.App")
        #expect(options.timeout == 10)
    }

    @Test func accessibilitySnapshotModeAcceptsOutputPathAndIncludeHidden() throws {
        let options = try AccessibilityOptions([
            "/tmp/loupe-snapshot.json",
            "--include-hidden",
            "--output", "/tmp/loupe-accessibility.json",
        ])

        #expect(options.snapshotURL.path == "/tmp/loupe-snapshot.json")
        #expect(options.includeHidden)
        #expect(options.outputURL?.path == "/tmp/loupe-accessibility.json")
    }
}
