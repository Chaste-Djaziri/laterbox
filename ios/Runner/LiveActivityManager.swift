import ActivityKit
import Foundation

@available(iOS 16.1, *)
public final class LiveActivityManager {
    public static let shared = LiveActivityManager()

    private var activeActivities: [String: Activity<LaterBoxActivityAttributes>] = [:]

    private init() {}

    public var isSupported: Bool {
        if #available(iOS 16.1, *) {
            return ActivityAuthorizationInfo().areActivitiesEnabled
        }
        return false
    }

    public func startActivity(
        id: String,
        title: String,
        subtitle: String? = nil,
        returnSchedule: String? = nil,
        captureType: String = "share",
        isCompleted: Bool = true,
        isError: Bool = false,
        autoDismissSeconds: Double = 3.5
    ) {
        guard #available(iOS 16.1, *), isSupported else { return }

        // End any existing activity with same ID
        endActivity(id: id)

        let attributes = LaterBoxActivityAttributes(captureId: id, captureType: captureType)
        let state = LaterBoxActivityAttributes.ContentState(
            title: title,
            subtitle: subtitle,
            returnSchedule: returnSchedule,
            isCompleted: isCompleted,
            isError: isError
        )

        do {
            let activity: Activity<LaterBoxActivityAttributes>
            if #available(iOS 16.2, *) {
                activity = try Activity.request(
                    attributes: attributes,
                    content: .init(state: state, staleDate: nil),
                    pushType: nil
                )
            } else {
                activity = try Activity.request(
                    attributes: attributes,
                    contentState: state,
                    pushType: nil
                )
            }
            activeActivities[id] = activity

            if autoDismissSeconds > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissSeconds) { [weak self] in
                    self?.endActivity(id: id)
                }
            }
        } catch {
            NSLog("[LaterBox] Failed to start Dynamic Island Live Activity: %@", error.localizedDescription)
        }
    }

    public func updateActivity(
        id: String,
        title: String? = nil,
        subtitle: String? = nil,
        returnSchedule: String? = nil,
        isCompleted: Bool? = nil,
        isError: Bool? = nil
    ) {
        guard #available(iOS 16.1, *), let activity = activeActivities[id] else { return }

        let currentState: LaterBoxActivityAttributes.ContentState
        if #available(iOS 16.2, *) {
            currentState = activity.content.state
        } else {
            currentState = activity.contentState
        }
        let updatedState = LaterBoxActivityAttributes.ContentState(
            title: title ?? currentState.title,
            subtitle: subtitle ?? currentState.subtitle,
            returnSchedule: returnSchedule ?? currentState.returnSchedule,
            isCompleted: isCompleted ?? currentState.isCompleted,
            isError: isError ?? currentState.isError
        )

        Task {
            if #available(iOS 16.2, *) {
                await activity.update(.init(state: updatedState, staleDate: nil))
            } else {
                await activity.update(using: updatedState)
            }
        }
    }

    public func endActivity(id: String) {
        guard #available(iOS 16.1, *), let activity = activeActivities.removeValue(forKey: id) else { return }

        Task {
            if #available(iOS 16.2, *) {
                await activity.end(nil, dismissalPolicy: .immediate)
            } else {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }

    public func endAllActivities() {
        guard #available(iOS 16.1, *) else { return }
        for (_, activity) in activeActivities {
            Task {
                if #available(iOS 16.2, *) {
                    await activity.end(nil, dismissalPolicy: .immediate)
                } else {
                    await activity.end(dismissalPolicy: .immediate)
                }
            }
        }
        activeActivities.removeAll()
    }
}
