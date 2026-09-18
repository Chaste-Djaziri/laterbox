# Changelog

All notable user-facing changes to LaterBox will be documented in this file.

## [Unreleased]

### Added
- **Web Landing Page 'How It Works' 4-Step Workflow**: Added the 4-step workflow storytelling section (Drop it, Choose when, Forget about it, It comes back) with interactive mockups and scroll-active step highlighting.
- **Web Landing Page Scroll Convergence Section**: Added an interactive scroll-driven animation section where scattered digital items (YouTube links, PDFs, PSDs, invoices, screenshots, notes) converge into the center as 'Later shouldn't mean lost' transforms into 'One place for everything later.'
- **Web Landing Page 'Later' Problem Section**: Added the "We all have a place called Later" problem statement section directly under the hero section, featuring behavioral cards for "Watch later", "Bookmarks", "Downloads", and "Open tabs".
- **Custom Return Time for Dynamic Island & Share Extension**: Added custom date and time scheduling to the iOS Dynamic Island companion modal and enhanced the custom time picker in the iOS Share Extension confirm modal.
- **Native ActivityKit Live Activities**: Added native iOS Dynamic Island Live Activity support via ActivityKit with compact leading/trailing, minimal, and expanded interactive views for share receipts and captures.
- **iOS Dynamic Island & Notch Companion**: Dynamic Island & Notch companion for iOS that expands to prompt user when copied content is detected (with quick "When" scheduling) and confirms saved items and share receipts directly from the Dynamic Island / Notch.
- **iOS Share Extension 'Choose When' Picker**: iOS Share Extension now prompts the user to choose when to return the item (Inbox, Later today, Tomorrow, Weekend, Someday, or custom date/time) before confirming.
- **iOS Share Extension App Group & Error Handling**: Enhanced shared storage reliability with atomic container writes, file protection, and explicit error diagnosis in the UI if App Group sharing or saving fails.
- **Video Attachment Player & Queue Mode**: Added a custom in-app video player for video attachments featuring custom play/pause icons, interactive progress scrubber, elapsed/total duration, and a Queue Mode with playlist drawer, auto-advance, and skip controls for multiple video attachments.
- **Web-Styled Search Icon**: Added a rounded search button (`⌘K`) in the Home dashboard header matching the web interface.

### Fixed
- **Web Mobile Layout**: Fixed mobile header layout in Next.js web app to be fully responsive, prevent overflowing action buttons, and fit mobile screens with safe-area insets.
- **Web Downloads**: Fixed terminal CLI quick script snippet command and copy action on download page.
- **iOS Dynamic Island Overlay**: Fixed a missing Overlay assertion error by removing the tooltip from the overlay close button and providing an Overlay widget ancestor.

### Removed
- **Web Landing Page Metrics Bar**: Removed the 4-item performance metrics bar (< 10ms SQLite, 100% Offline-First, 7 Platforms, 0 Trackers) from the landing page.

### Changed
- **Landing Page 'Later' Quote Cards**: Added subtle tilt rotations to problem cards with smooth straighten-on-hover animation and luminous border highlight.
- **Web Landing Page Hero**: Updated headline to "Drop it now. Deal with it later.", updated subtext, added "TRY IT ↓" preview indicator, and embedded a real live guest mode application sandbox adhering to the web theme palette.
- **Web Attribution**: Updated author attribution to MiCorp ([micorp.pro](https://micorp.pro)).
- **iOS Clipboard Capture Notification**: Positioned the clipboard capture notification and confirmation card directly under the notch and Dynamic Island.
- **macOS App Icon**: Updated macOS app icon to use the white app icon with black icon in light mode, and pure black background with white icon in dark mode.
- **Desktop Quick Capture Shortcut**: Updated default global capture shortcut to Control+Option on macOS (`⌃ ⌥ Space`) and `Ctrl + Shift + L` on Windows.
- **macOS Title Bar**: Unified title bar and traffic light area into a single solid color by making the titlebar transparent with a matching background.
- **Desktop Sidebar Redesign**:
  - Expanded sidebar width to 268px for a spacious desktop layout.
  - Aligned brand header, typography, and color tokens with web UI (`#F7F5EE` light, `#161614` dark).
  - Taller 42px tab pills with 18px icons and bold typography.
  - Removed hover background/color states on unselected sidebar items.
  - Removed sidebar collapse toggle chevron icon.
- **Home Dashboard**: Removed duplicate greeting in mobile body to keep only the single bold greeting in the AppBar header.
- **Home Dashboard**: Summary cards now show "Waiting in Inbox" and "Returning today" side by side, with "Upcoming" stretching full width below.
- **Home Dashboard**: Mobile AppBar title now shows the greeting (e.g. "Good morning.") instead of "Home".
- **Settings**: Version display now reads the real device build version via PackageInfo instead of a hardcoded string.
- **Settings**: App Icon section is now only visible on iOS devices.
- **Item List Rows**: Show scheduled return time instead of relative timestamp when a return time is set.
- **Item Cards**: Show scheduled return time instead of relative timestamp in card views when a return time is set.
- **Home Dashboard**: Show next scheduled return time in the Upcoming summary card.
- **Quick Capture Modal**: Made "Choose when · <time>" text white for clean contrast against the modal backdrop.
- **macOS Notch Companion**: Custom collapsed pill shape with minimal top corners and full-round bottom corners.
- **Desktop Sidebar**: Added hover state and pointer cursor on interactive sidebar links.
- **macOS Home Header**: Removed redundant "Home" AppBar title on macOS and desktop platforms in favor of a clean greeting header.
- **Sidebar Navigation**: Removed redundant "Search" tab from sidebar navigation in favor of the header search button and `⌘K` shortcut.
- **Apps Download Link**: Desktop sidebar "Apps" link now points directly to the external download page (`https://laterbox.dev/download`).
- **Platform Architecture**: Removed legacy Flutter web build configuration and web-specific updater services in favor of the dedicated `laterbox-web` Next.js application.
- **Download Page**: Download page now only shows iOS and Android downloads. macOS, Windows, Linux, and browser extension downloads are hidden for now.
