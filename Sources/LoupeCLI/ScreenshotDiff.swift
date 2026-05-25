import CoreGraphics
import Foundation
import ImageIO
import LoupeCLIModel

struct LoupeScreenshotDiffSummary: Codable, Equatable {
    var beforePath: String
    var afterPath: String
    var beforeSize: LoupeScreenshotPixelSize
    var afterSize: LoupeScreenshotPixelSize
    var dimensionsMatch: Bool
    var comparedPixels: Int
    var changedPixels: Int
    var changedPixelRatio: Double
    var meanColorDelta: Double
    var maxColorDelta: Int
}

struct LoupeScreenshotPixelSize: Codable, Equatable {
    var width: Int
    var height: Int
}

enum ScreenshotDiffer {
    static func diff(before beforeURL: URL, after afterURL: URL) throws -> LoupeScreenshotDiffSummary {
        let before = try RGBAImage(url: beforeURL)
        let after = try RGBAImage(url: afterURL)

        let comparedWidth = min(before.width, after.width)
        let comparedHeight = min(before.height, after.height)
        let comparedPixels = comparedWidth * comparedHeight

        var changedPixels = 0
        var totalColorDelta = 0
        var maxColorDelta = 0
        let changedThreshold = 8

        if comparedPixels > 0 {
            for y in 0..<comparedHeight {
                let beforeRow = y * before.bytesPerRow
                let afterRow = y * after.bytesPerRow
                for x in 0..<comparedWidth {
                    let beforeOffset = beforeRow + x * 4
                    let afterOffset = afterRow + x * 4
                    let delta = abs(Int(before.data[beforeOffset]) - Int(after.data[afterOffset]))
                        + abs(Int(before.data[beforeOffset + 1]) - Int(after.data[afterOffset + 1]))
                        + abs(Int(before.data[beforeOffset + 2]) - Int(after.data[afterOffset + 2]))
                    totalColorDelta += delta
                    maxColorDelta = max(maxColorDelta, delta)
                    if delta > changedThreshold {
                        changedPixels += 1
                    }
                }
            }
        }

        let dimensionsMatch = before.width == after.width && before.height == after.height
        let ratio = comparedPixels == 0 ? 0 : Double(changedPixels) / Double(comparedPixels)
        let meanDelta = comparedPixels == 0 ? 0 : Double(totalColorDelta) / Double(comparedPixels * 3)

        return LoupeScreenshotDiffSummary(
            beforePath: beforeURL.path,
            afterPath: afterURL.path,
            beforeSize: LoupeScreenshotPixelSize(width: before.width, height: before.height),
            afterSize: LoupeScreenshotPixelSize(width: after.width, height: after.height),
            dimensionsMatch: dimensionsMatch,
            comparedPixels: comparedPixels,
            changedPixels: changedPixels,
            changedPixelRatio: ratio,
            meanColorDelta: meanDelta,
            maxColorDelta: maxColorDelta
        )
    }
}

private struct RGBAImage {
    var width: Int
    var height: Int
    var bytesPerRow: Int
    var data: [UInt8]

    init(url: URL) throws {
        guard
            let source = CGImageSourceCreateWithURL(url as CFURL, nil),
            let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
        else {
            throw CLIError("Could not decode PNG image: \(url.path)")
        }

        width = image.width
        height = image.height
        bytesPerRow = width * 4
        data = [UInt8](repeating: 0, count: bytesPerRow * height)

        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
            | CGBitmapInfo.byteOrder32Big.rawValue
        try data.withUnsafeMutableBytes { buffer in
            guard
                let context = CGContext(
                    data: buffer.baseAddress,
                    width: width,
                    height: height,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: bitmapInfo
                )
            else {
                throw CLIError("Could not create bitmap context for PNG image: \(url.path)")
            }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}
