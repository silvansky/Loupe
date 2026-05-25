import Foundation
import LoupeCLIModel
import LoupeCore

struct LoupeNodeDiffSummary: Codable {
    var key: String
    var ref: String
    var typeName: String
    var role: String?
    var testID: String?
    var text: String?
    var frame: LoupeRect?
    var isVisible: Bool?
}

extension LoupeNodeDiffSummary {
    var isVisibleForSummary: Bool {
        isVisible != false
    }
}
