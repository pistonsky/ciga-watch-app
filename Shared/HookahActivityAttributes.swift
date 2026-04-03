import ActivityKit
import Foundation

struct HookahActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var startDate: Date
        var isActive: Bool
    }
}
