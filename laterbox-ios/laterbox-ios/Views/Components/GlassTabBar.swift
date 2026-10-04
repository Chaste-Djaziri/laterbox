//
//  GlassTabBar.swift
//  laterbox-ios
//
//  Created by Chaste Djaziri on 04.10.26.
//

import SwiftUI

public enum LBTab: Int, CaseIterable {
    case home = 0
    case inbox = 1
    case returns = 2
    case library = 3
    case settings = 4

    public var title: String {
        switch self {
        case .home: return "Home"
        case .inbox: return "Inbox"
        case .returns: return "Returns"
        case .library: return "Library"
        case .settings: return "Settings"
        }
    }

    public var icon: String {
        switch self {
        case .home: return "house.fill"
        case .inbox: return "tray.fill"
        case .returns: return "calendar.badge.clock"
        case .library: return "books.vertical.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct GlassTabBar: View {
    @Binding public var selectedTab: LBTab
    public var onQuickCapture: () -> Void

    public init(selectedTab: Binding<LBTab>, onQuickCapture: @escaping () -> Void) {
        self._selectedTab = selectedTab
        self.onQuickCapture = onQuickCapture
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Home Tab
            tabButton(for: .home)
            tabButton(for: .inbox)

            // Center Quick Capture Action
            Button(action: {
                LBHaptic.medium()
                onQuickCapture()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.lbAmber, Color.lbAmberDark],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .shadow(color: Color.lbAmber.opacity(0.4), radius: 8, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.black)
                }
            }
            .frame(maxWidth: .infinity)

            tabButton(for: .returns)
            tabButton(for: .library)
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 16)
        .liquidGlassCard(cornerRadius: 32, borderOpacity: 0.3)
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: LBTab) -> some View {
        Button(action: {
            LBHaptic.light()
            selectedTab = tab
        }) {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: selectedTab == tab ? .bold : .regular))
                    .foregroundColor(selectedTab == tab ? Color.lbAmber : .secondary)

                Text(tab.title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                    .foregroundColor(selectedTab == tab ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}
