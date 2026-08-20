import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/desktop/desktop_actions.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/settings/desktop_settings.dart';
import '../../../core/settings/desktop_shortcut.dart';
import '../../../core/settings/settings_providers.dart';

const _accessibilitySettingsUrl =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility';

/// Desktop controls & settings.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings =
        ref.watch(desktopSettingsProvider).value ?? DesktopSettings.defaults();
    final actions = ref.watch(desktopActionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        children: [
          _SectionHeader('Quick Capture'),
          _ShortcutTile(shortcut: settings.quickCaptureShortcut),
          const _SectionHeader('Capture'),
          SwitchListTile(
            title: const Text('Use selected text when available'),
            subtitle: const Text('Falls back to the clipboard otherwise'),
            secondary: const Icon(Icons.text_fields_rounded),
            value: settings.useSelectedText,
            onChanged: (value) => unawaited(actions.setUseSelectedText(value)),
          ),
          const _AccessibilityTile(),
          const _SectionHeader('Behavior'),
          SwitchListTile(
            title: const Text('Close Quick Capture when focus is lost'),
            subtitle: const Text('Only while capture is active'),
            secondary: const Icon(Icons.center_focus_weak_rounded),
            value: settings.closeOnFocusLoss,
            onChanged: (value) => unawaited(actions.setCloseOnFocusLoss(value)),
          ),
          const _SectionHeader('Startup'),
          SwitchListTile(
            title: const Text('Keep LaterBox running when window closes'),
            subtitle: const Text('Stays in the menu bar instead of quitting'),
            secondary: const Icon(Icons.power_settings_new_rounded),
            value: settings.keepRunningOnWindowClose,
            onChanged: (value) =>
                unawaited(actions.setKeepRunningOnWindowClose(value)),
          ),
          SwitchListTile(
            title: const Text('Launch LaterBox at login'),
            subtitle: const Text('Starts quietly in the menu bar'),
            secondary: const Icon(Icons.login_rounded),
            value: settings.launchAtLogin,
            onChanged: (value) => unawaited(actions.setLaunchAtLogin(value)),
          ),
          const _SectionHeader('Menu Bar'),
          SwitchListTile(
            title: const Text('Show LaterBox in menu bar'),
            secondary: const Icon(Icons.menu_rounded),
            value: settings.showInMenuBar,
            onChanged: (value) => unawaited(actions.setShowInMenuBar(value)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});

  final DesktopShortcut shortcut;

  Future<void> _pick(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ShortcutDialog(current: shortcut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.keyboard_rounded),
      title: const Text('Shortcut'),
      subtitle: Text(
        shortcut.displayLabel,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'Menlo',
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: FilledButton.tonal(
        onPressed: () => _pick(context),
        child: const Text('Change shortcut'),
      ),
    );
  }
}

/// Records a new key combination and reports conflicts through the action's
/// return value.
class _ShortcutDialog extends ConsumerStatefulWidget {
  const _ShortcutDialog({required this.current});

  final DesktopShortcut current;

  @override
  ConsumerState<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends ConsumerState<_ShortcutDialog> {
  final _focusNode = FocusNode();
  DesktopShortcut? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final preview = _preview;
    if (preview == null) return;
    final ok = await ref
        .read(desktopActionsProvider)
        .changeQuickCaptureShortcut(preview);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error =
            "This shortcut couldn't be registered. It may already be used by "
            'another application.';
      });
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.physicalKey == PhysicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return;
    }
    if (_isModifier(event.physicalKey)) return;

    final modifiers = _pressedModifiers();
    if (modifiers.isEmpty) {
      setState(() {
        _error = 'Add a modifier like ⌥ or ⌘ for a safe global shortcut.';
      });
      return;
    }
    setState(() {
      _error = null;
      _preview = DesktopShortcut(
        keyId: event.physicalKey.usbHidUsage,
        modifiers: modifiers,
      );
    });
  }

  bool _isModifier(PhysicalKeyboardKey key) {
    return key == PhysicalKeyboardKey.altLeft ||
        key == PhysicalKeyboardKey.altRight ||
        key == PhysicalKeyboardKey.controlLeft ||
        key == PhysicalKeyboardKey.controlRight ||
        key == PhysicalKeyboardKey.shiftLeft ||
        key == PhysicalKeyboardKey.shiftRight ||
        key == PhysicalKeyboardKey.metaLeft ||
        key == PhysicalKeyboardKey.metaRight;
  }

  List<DesktopModifier> _pressedModifiers() {
    final physical = HardwareKeyboard.instance.physicalKeysPressed;
    final modifiers = <DesktopModifier>[];
    if (physical.contains(PhysicalKeyboardKey.altLeft) ||
        physical.contains(PhysicalKeyboardKey.altRight)) {
      modifiers.add(DesktopModifier.alt);
    }
    if (physical.contains(PhysicalKeyboardKey.controlLeft) ||
        physical.contains(PhysicalKeyboardKey.controlRight)) {
      modifiers.add(DesktopModifier.control);
    }
    if (physical.contains(PhysicalKeyboardKey.shiftLeft) ||
        physical.contains(PhysicalKeyboardKey.shiftRight)) {
      modifiers.add(DesktopModifier.shift);
    }
    if (physical.contains(PhysicalKeyboardKey.metaLeft) ||
        physical.contains(PhysicalKeyboardKey.metaRight)) {
      modifiers.add(DesktopModifier.meta);
    }
    return modifiers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    return AlertDialog(
      title: const Text('Change Quick Capture shortcut'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Press the new key combination.'),
            const SizedBox(height: 16),
            Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                preview?.displayLabel ?? 'Press a combination',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (_, event) {
                _handleKey(event);
                return KeyEventResult.handled;
              },
              child: const SizedBox(height: 24, width: double.infinity),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: preview == null ? null : _save,
          child: const Text('Save shortcut'),
        ),
      ],
    );
  }
}

class _AccessibilityTile extends ConsumerWidget {
  const _AccessibilityTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trusted = ref.watch(accessibilityTrustedProvider);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.accessibility_new_rounded),
      title: const Text('Selected text capture'),
      subtitle: Text(
        trusted.when(
          data: (granted) => granted
              ? 'Accessibility access enabled'
              : 'Accessibility access required',
          loading: () => 'Checking permission…',
          error: (_, _) => 'Accessibility access required',
        ),
      ),
      trailing: trusted.when(
        data: (granted) => granted
            ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600)
            : FilledButton.tonal(
                onPressed: () =>
                    unawaited(launchUrl(Uri.parse(_accessibilitySettingsUrl))),
                child: const Text('Open System Settings'),
              ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => FilledButton.tonal(
          onPressed: () =>
              unawaited(launchUrl(Uri.parse(_accessibilitySettingsUrl))),
          child: const Text('Open System Settings'),
        ),
      ),
    );
  }
}
