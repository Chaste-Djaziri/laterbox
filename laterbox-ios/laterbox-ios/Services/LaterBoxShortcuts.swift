import Foundation
import AppIntents

public struct LaterBoxShortcuts: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: QuickSaveIntent(),
            phrases: [
                "Quick Save to \(.applicationName)",
                "Save to \(.applicationName)",
                "Add to \(.applicationName)",
                "Quick capture in \(.applicationName)"
            ],
            shortTitle: "Quick Save to LaterBox",
            systemImageName: "plus.square.fill.on.square.fill"
        )
    }
}
