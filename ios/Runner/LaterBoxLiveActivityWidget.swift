import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
public struct LaterBoxLiveActivityWidget: Widget {
    public init() {}

    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: LaterBoxActivityAttributes.self) { context in
            // Lock Screen presentation banner
            LaterBoxLockScreenView(state: context.state)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isError ? "exclamationmark.triangle.fill" : "bookmark.fill")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(context.state.isError ? .red : Color(red: 0.90, green: 0.93, blue: 0.69))
                        Text("LaterBox")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.leading, 8)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    if let returnSchedule = context.state.returnSchedule, !returnSchedule.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 9))
                            Text(returnSchedule)
                                .font(.system(size: 11, weight: .bold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.90, green: 0.93, blue: 0.69).opacity(0.18))
                        .foregroundColor(Color(red: 0.90, green: 0.93, blue: 0.69))
                        .cornerRadius(10)
                        .padding(.trailing, 8)
                    } else if context.state.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(Color(red: 0.90, green: 0.93, blue: 0.69))
                            .padding(.trailing, 8)
                    }
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(context.state.title)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        if let subtitle = context.state.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.system(size: 12))
                                .foregroundColor(Color(white: 0.70))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 10)
                    .padding(.top, 4)
                }
            } compactLeading: {
                // Compact Leading: Mini brand icon
                HStack(spacing: 3) {
                    Image(systemName: context.state.isError ? "exclamationmark.circle.fill" : "bookmark.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(context.state.isError ? .red : Color(red: 0.90, green: 0.93, blue: 0.69))
                }
                .padding(.leading, 4)
            } compactTrailing: {
                // Compact Trailing: Return tag or checkmark
                HStack(spacing: 3) {
                    if context.state.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundColor(Color(red: 0.90, green: 0.93, blue: 0.69))
                    } else if let returnSchedule = context.state.returnSchedule, !returnSchedule.isEmpty {
                        Text(returnSchedule)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.90, green: 0.93, blue: 0.69))
                    } else {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white)
                    }
                }
                .padding(.trailing, 4)
            } minimal: {
                // Minimal: Shared island space icon
                Image(systemName: context.state.isError ? "exclamationmark.circle.fill" : "bookmark.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(context.state.isError ? .red : Color(red: 0.90, green: 0.93, blue: 0.69))
            }
            .keylineTint(Color(red: 0.90, green: 0.93, blue: 0.69))
        }
    }
}

@available(iOS 16.1, *)
private struct LaterBoxLockScreenView: View {
    let state: LaterBoxActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(red: 0.90, green: 0.93, blue: 0.69).opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: state.isError ? "exclamationmark.triangle.fill" : (state.isCompleted ? "checkmark" : "bookmark.fill"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(state.isError ? .red : Color(red: 0.90, green: 0.93, blue: 0.69))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(state.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let subtitle = state.subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(Color(white: 0.70))
                        .lineLimit(1)
                }
            }

            Spacer()

            if let returnSchedule = state.returnSchedule, !returnSchedule.isEmpty {
                Text(returnSchedule)
                    .font(.system(size: 11, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.90, green: 0.93, blue: 0.69).opacity(0.18))
                    .foregroundColor(Color(red: 0.90, green: 0.93, blue: 0.69))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.08, green: 0.08, blue: 0.09))
    }
}
