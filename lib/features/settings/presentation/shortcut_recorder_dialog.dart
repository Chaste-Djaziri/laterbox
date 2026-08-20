import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/settings/desktop_shortcut.dart';

class ShortcutRecorderDialog extends StatefulWidget {
  const ShortcutRecorderDialog({
    super.key,
    required this.currentShortcut,
    required this.onTestRegister,
  });

  final DesktopShortcut currentShortcut;
  final Future<bool> Function(DesktopShortcut shortcut) onTestRegister;

  static Future<DesktopShortcut?> show(
    BuildContext context, {
    required DesktopShortcut currentShortcut,
    required Future<bool> Function(DesktopShortcut shortcut) onTestRegister,
  }) {
    return showDialog<DesktopShortcut>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ShortcutRecorderDialog(
        currentShortcut: currentShortcut,
        onTestRegister: onTestRegister,
      ),
    );
  }

  @override
  State<ShortcutRecorderDialog> createState() => _ShortcutRecorderDialogState();
}

class _ShortcutRecorderDialogState extends State<ShortcutRecorderDialog> {
  late DesktopShortcut _recordedShortcut;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _recordedShortcut = widget.currentShortcut;
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.physicalKey;

    // Ignore modifier-only key presses as main key
    if (key == PhysicalKeyboardKey.altLeft ||
        key == PhysicalKeyboardKey.altRight ||
        key == PhysicalKeyboardKey.controlLeft ||
        key == PhysicalKeyboardKey.controlRight ||
        key == PhysicalKeyboardKey.metaLeft ||
        key == PhysicalKeyboardKey.metaRight ||
        key == PhysicalKeyboardKey.shiftLeft ||
        key == PhysicalKeyboardKey.shiftRight) {
      return;
    }

    final modifiers = <DesktopModifier>[];
    final keysPressed = HardwareKeyboard.instance.logicalKeysPressed;

    if (keysPressed.contains(LogicalKeyboardKey.altLeft) ||
        keysPressed.contains(LogicalKeyboardKey.altRight) ||
        HardwareKeyboard.instance.isAltPressed) {
      modifiers.add(DesktopModifier.alt);
    }
    if (keysPressed.contains(LogicalKeyboardKey.controlLeft) ||
        keysPressed.contains(LogicalKeyboardKey.controlRight) ||
        HardwareKeyboard.instance.isControlPressed) {
      modifiers.add(DesktopModifier.control);
    }
    if (keysPressed.contains(LogicalKeyboardKey.metaLeft) ||
        keysPressed.contains(LogicalKeyboardKey.metaRight) ||
        HardwareKeyboard.instance.isMetaPressed) {
      modifiers.add(DesktopModifier.meta);
    }
    if (keysPressed.contains(LogicalKeyboardKey.shiftLeft) ||
        keysPressed.contains(LogicalKeyboardKey.shiftRight) ||
        HardwareKeyboard.instance.isShiftPressed) {
      modifiers.add(DesktopModifier.shift);
    }

    // Default to Alt if no modifier was pressed
    if (modifiers.isEmpty) {
      modifiers.add(DesktopModifier.alt);
    }

    setState(() {
      _errorMessage = null;
      _recordedShortcut = DesktopShortcut(
        keyId: key.usbHidUsage,
        modifiers: modifiers,
      );
    });
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    final success = await widget.onTestRegister(_recordedShortcut);
    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(_recordedShortcut);
    } else {
      setState(() {
        _isSaving = false;
        _errorMessage =
            "This shortcut couldn't be registered. It may already be used by another application.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: _handleKeyEvent,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Change Quick Capture Shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Press your desired key combination on your keyboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 24),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Text(
                _recordedShortcut.displayLabel,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: theme.colorScheme.error,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _recordedShortcut = DesktopShortcut.defaultQuickCapture();
                _errorMessage = null;
              });
            },
            child: const Text('Reset (⌥ Space)'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Shortcut'),
          ),
        ],
      ),
    );
  }
}
