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
            shortTitle: "Quick Save",
            systemImageName: "plus.square.fill.on.square.fill"
        )
        AppShortcut(
            intent: OpenQuickSaveModalIntent(),
            phrases: [
                "Open Quick Save in \(.applicationName)",
                "Add Item in \(.applicationName)"
            ],
            shortTitle: "Add Item",
            systemImageName: "square.and.pencil"
        )
    }
}
