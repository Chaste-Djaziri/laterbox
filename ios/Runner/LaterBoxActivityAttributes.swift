import ActivityKit
import Foundation

@available(iOS 16.1, *)
public struct LaterBoxActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var title: String
        public var subtitle: String?
        public var returnSchedule: String?
        public var isCompleted: Bool
        public var isError: Bool

        public init(
            title: String,
            subtitle: String? = nil,
            returnSchedule: String? = nil,
            isCompleted: Bool = false,
            isError: Bool = false
        ) {
            self.title = title
            self.subtitle = subtitle
            self.returnSchedule = returnSchedule
            self.isCompleted = isCompleted
            self.isError = isError
        }
    }

    public var captureId: String
    public var captureType: String

    public init(captureId: String, captureType: String = "share") {
        self.captureId = captureId
        self.captureType = captureType
    }
}
