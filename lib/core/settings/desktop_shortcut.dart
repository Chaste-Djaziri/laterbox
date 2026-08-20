import 'package:flutter/services.dart';

/// The modifier keys of a desktop shortcut, kept platform-agnostic so the
/// model can be persisted and shared without touching native bindings.
enum DesktopModifier { alt, control, shift, meta }

/// A system-wide keyboard shortcut, persisted by its physical key code so it
/// stays stable across keyboard layouts.
class DesktopShortcut {
  const DesktopShortcut({required this.keyId, required this.modifiers});

  /// `PhysicalKeyboardKey.usbHidUsage` of the main key.
  final int keyId;

  final List<DesktopModifier> modifiers;

  /// The default quick capture shortcut: `⌥ Space`.
  static DesktopShortcut defaultQuickCapture() {
    return DesktopShortcut(
      keyId: PhysicalKeyboardKey.space.usbHidUsage,
      modifiers: const [DesktopModifier.alt],
    );
  }

  /// The physical key this shortcut maps to, or `null` when the persisted id
  /// no longer exists on this Flutter build.
  PhysicalKeyboardKey? get physicalKey =>
      PhysicalKeyboardKey.findKeyByCode(keyId);

  String get displayLabel {
    final modifierPart = modifiers.map(_modifierSymbol).join();
    final keyPart = physicalKey?.debugName ?? '';
    final keyName = keyPart.isEmpty ? 'Key $keyId' : _friendlyKeyName(keyPart);
    return modifierPart.isEmpty ? keyName : '$modifierPart$keyName';
  }

  static String _modifierSymbol(DesktopModifier modifier) {
    switch (modifier) {
      case DesktopModifier.alt:
        return '⌥ ';
      case DesktopModifier.control:
        return '⌃ ';
      case DesktopModifier.shift:
        return '⇧ ';
      case DesktopModifier.meta:
        return '⌘ ';
    }
  }

  static String _friendlyKeyName(String debugName) {
    if (debugName.startsWith('Key ')) return debugName.substring(4);
    return debugName;
  }

  Map<String, dynamic> toJson() => {
        'keyId': keyId,
        'modifiers': modifiers.map((m) => m.name).toList(),
      };

  factory DesktopShortcut.fromJson(Map<String, dynamic> json) {
    final keyId = json['keyId'];
    final rawModifiers = json['modifiers'];
    if (keyId is! int || rawModifiers is! List) {
      return DesktopShortcut.defaultQuickCapture();
    }
    final modifiers = rawModifiers
        .map((m) => DesktopModifier.values.asNameMap()[m])
        .whereType<DesktopModifier>()
        .toList();
    return DesktopShortcut(keyId: keyId, modifiers: modifiers);
  }

  /// Whether [other] presses the same physical key with the same modifiers.
  bool isSameAs(DesktopShortcut other) {
    if (keyId != other.keyId) return false;
    if (modifiers.length != other.modifiers.length) return false;
    return modifiers.toSet().containsAll(other.modifiers);
  }
}