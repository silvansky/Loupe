import CoreGraphics
import Foundation
import ImageIO
import Testing
@testable import LoupeCLI

@Suite struct ScreenshotDiffTests {
    @Test func screenshotDifferReportsChangedPixels() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("loupe-screenshot-diff-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let beforeURL = directory.appendingPathComponent("before.png")
        let afterURL = directory.appendingPathComponent("after.png")
        try writePNG(
            [
                RGBA(red: 255, green: 0, blue: 0, alpha: 255),
                RGBA(red: 0, green: 255, blue: 0, alpha: 255),
            ],
            width: 2,
            height: 1,
            to: beforeURL
        )
        try writePNG(
            [
                RGBA(red: 255, green: 0, blue: 0, alpha: 255),
                RGBA(red: 0, green: 0, blue: 255, alpha: 255),
            ],
            width: 2,
            height: 1,
            to: afterURL
        )

        let diff = try ScreenshotDiffer.diff(before: beforeURL, after: afterURL)

        #expect(diff.beforeSize == LoupeScreenshotPixelSize(width: 2, height: 1))
        #expect(diff.afterSize == LoupeScreenshotPixelSize(width: 2, height: 1))
        #expect(diff.dimensionsMatch)
        #expect(diff.comparedPixels == 2)
        #expect(diff.changedPixels == 1)
        #expect(diff.changedPixelRatio == 0.5)
        #expect(diff.maxColorDelta > 0)
    }

    @Test func traceNotesFlagLargeVisualOnlyChanges() {
        let notes = LoupeCLI.traceNotes(
            diff: LoupeSnapshotDiff(
                beforeSnapshotID: "before",
                afterSnapshotID: "after",
                appeared: [],
                disappeared: [],
                changed: []
            ),
            screenshotDiff: screenshotDiff(changedPixelRatio: 0.98)
        )

        #expect(notes.count == 1)
        #expect(notes[0].contains("large screenshot change"))
    }

    @Test func traceNotesSkipWhenSnapshotAlsoChangedSubstantially() {
        let notes = LoupeCLI.traceNotes(
            diff: LoupeSnapshotDiff(
                beforeSnapshotID: "before",
                afterSnapshotID: "after",
                appeared: (0..<6).map { index in
                    LoupeNodeDiffSummary(
                        key: "node\(index)",
                        ref: "n\(index)",
                        typeName: "UIView",
                        role: nil,
                        testID: nil,
                        text: nil,
                        frame: nil
                    )
                },
                disappeared: [],
                changed: []
            ),
            screenshotDiff: screenshotDiff(changedPixelRatio: 0.98)
        )

        #expect(notes.isEmpty)
    }

    @Test func traceNotesTreatHiddenDiffAsMinimalSnapshotChange() {
        let notes = LoupeCLI.traceNotes(
            diff: LoupeSnapshotDiff(
                beforeSnapshotID: "before",
                afterSnapshotID: "after",
                appeared: (0..<6).map { index in
                    LoupeNodeDiffSummary(
                        key: "hidden\(index)",
                        ref: "n\(index)",
                        typeName: "UIView",
                        role: nil,
                        testID: nil,
                        text: nil,
                        frame: nil,
                        isVisible: false
                    )
                },
                disappeared: [],
                changed: []
            ),
            screenshotDiff: screenshotDiff(changedPixelRatio: 0.98)
        )

        #expect(notes.count == 1)
    }

    private struct RGBA {
        var red: UInt8
        var green: UInt8
        var blue: UInt8
        var alpha: UInt8
    }

    private func writePNG(_ pixels: [RGBA], width: Int, height: Int, to url: URL) throws {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(width * height * 4)
        for pixel in pixels {
            bytes.append(pixel.red)
            bytes.append(pixel.green)
            bytes.append(pixel.blue)
            bytes.append(pixel.alpha)
        }

        let data = Data(bytes)
        guard let provider = CGDataProvider(data: data as CFData) else {
            throw TestImageError(message: "Could not create test image data provider")
        }
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue
        guard let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: bitmapInfo),
            provider: provider,
            decode: nil,
            shouldInterpolate: false,
            intent: .defaultIntent
        ) else {
            throw TestImageError(message: "Could not create test image")
        }
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
            throw TestImageError(message: "Could not create test PNG destination")
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw TestImageError(message: "Could not write test PNG")
        }
    }

    private struct TestImageError: Error {
        var message: String
    }

    private func screenshotDiff(changedPixelRatio: Double) -> LoupeScreenshotDiffSummary {
        LoupeScreenshotDiffSummary(
            beforePath: "/tmp/before.png",
            afterPath: "/tmp/after.png",
            beforeSize: LoupeScreenshotPixelSize(width: 10, height: 10),
            afterSize: LoupeScreenshotPixelSize(width: 10, height: 10),
            dimensionsMatch: true,
            comparedPixels: 100,
            changedPixels: Int(changedPixelRatio * 100),
            changedPixelRatio: changedPixelRatio,
            meanColorDelta: 10,
            maxColorDelta: 255
        )
    }
}
