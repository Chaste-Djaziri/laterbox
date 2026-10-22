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
            ControlWidgetButton(action: OpenQuickSaveControlIntent()) {
                Label("Quick Save to LaterBox", systemImage: "plus.square.fill.on.square.fill")
            }
        }
        .displayName("Quick Save to LaterBox")
        .description("Open the Quick Save composer in LaterBox.")
    }
}

@available(iOS 18.0, *)
struct OpenQuickSaveControlIntent: AppIntent {
    static var title: LocalizedStringResource = "Open LaterBox Quick Save"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults(suiteName: "group.pro.micorp.laterbox")?
            .set(true, forKey: "openQuickSaveFromControl")
        return .result()
    }
}
