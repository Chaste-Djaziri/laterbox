# Changelog

All notable user-facing changes to LaterBox will be documented in this file.

## [Unreleased]

### Added
- **Web-Styled Search Icon**: Added a rounded search button (`⌘K`) in the Home dashboard header matching the web interface.

### Changed
- **macOS Title Bar**: Unified title bar and traffic light area into a single solid color by making the titlebar transparent with a matching background.
- **Desktop Sidebar Redesign**:
  - Expanded sidebar width to 268px for a spacious desktop layout.
  - Aligned brand header, typography, and color tokens with web UI (`#F7F5EE` light, `#161614` dark).
  - Taller 42px tab pills with 18px icons and bold typography.
  - Removed hover background/color states on unselected sidebar items.
  - Removed sidebar collapse toggle chevron icon.
- **macOS Notch Companion**: Custom collapsed pill shape with minimal top corners and full-round bottom corners.
- **Desktop Sidebar**: Added hover state and pointer cursor on interactive sidebar links.
- **macOS Home Header**: Removed redundant "Home" AppBar title on macOS and desktop platforms in favor of a clean greeting header.
- **Sidebar Navigation**: Removed redundant "Search" tab from sidebar navigation in favor of the header search button and `⌘K` shortcut.
- **Apps Download Link**: Desktop sidebar "Apps" link now points directly to the external download page (`https://laterbox.dev/download`).
- **Platform Architecture**: Removed legacy Flutter web build configuration and web-specific updater services in favor of the dedicated `laterbox-web` Next.js application.
