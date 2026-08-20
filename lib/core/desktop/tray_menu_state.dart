/// The account/sync summary shown in the menu-bar menu.
enum DesktopMenuAccountStatus { synced, offline, guest }

/// Everything the menu-bar menu needs to render its status section.
class DesktopMenuState {
  const DesktopMenuState({
    required this.accountStatus,
    required this.quickCaptureShortcutLabel,
    this.email,
  });

  final DesktopMenuAccountStatus accountStatus;

  /// Display label of the current quick capture shortcut (e.g. `⌥ Space`).
  final String quickCaptureShortcutLabel;

  /// Signed-in email, shown under the sync status when present.
  final String? email;

  /// The two status lines for the menu, e.g. `✓ Synced` / `Signed in as a@b`.
  List<String> statusLines() {
    switch (accountStatus) {
      case DesktopMenuAccountStatus.synced:
        final lines = ['✓ Synced'];
        final email = this.email;
        if (email != null) lines.add('Signed in as $email');
        return lines;
      case DesktopMenuAccountStatus.offline:
        return ['Offline — changes saved locally'];
      case DesktopMenuAccountStatus.guest:
        return ['Guest mode'];
    }
  }
}