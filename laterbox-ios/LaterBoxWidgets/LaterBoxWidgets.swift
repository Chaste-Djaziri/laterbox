import WidgetKit
import SwiftUI
import AppIntents

@main
struct LaterBoxWidgetsBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 18.0, *) {
            LaterBoxQuickSaveControl()
        }
    }
}

@available(iOS 18.0, *)
struct LaterBoxQuickSaveControl: ControlWidget {
    static let kind: String = "pro.micorp.laterbox.quickSaveControl"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: QuickSaveIntent()) {
                Label("Quick Save to LaterBox", systemImage: "plus.square.fill.on.square.fill")
            }
        }
        .displayName("Quick Save to LaterBox")
        .description("Prompt to save a note or link to LaterBox without opening the app.")
    }
}
