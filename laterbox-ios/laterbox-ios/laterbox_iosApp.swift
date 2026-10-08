//
//  laterbox_iosApp.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI
import SwiftData

@main
struct laterbox_iosApp: App {
    @ObservedObject private var storeKit = StoreKitManager.shared
    @UIApplicationDelegateAdaptor(ReturnNotificationDelegate.self) private var notificationDelegate
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LBItem.self,
            LBCollection.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}
