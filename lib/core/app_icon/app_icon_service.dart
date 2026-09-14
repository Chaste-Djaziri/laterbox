import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Represents an available app icon variant.
class AppIconOption {
  const AppIconOption({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.assetPath,
  });

  /// Unique identifier matching iOS CFBundleAlternateIcons (`null` for default icon).
  final String? id;

  /// User-facing display title.
  final String name;

  /// Short description of the aesthetic palette.
  final String subtitle;

  /// In-app preview asset path.
  final String assetPath;

  bool get isDefault => id == null;

  static const defaultIcon = AppIconOption(
    id: null,
    name: 'Classic Light',
    subtitle: 'Paper & Ink',
    assetPath: 'assets/branding/icons/icon_default.png',
  );

  static const dark = AppIconOption(
    id: 'AppIcon-Dark',
    name: 'Midnight Dark',
    subtitle: 'Electric lime on ink',
    assetPath: 'assets/branding/icons/icon_dark.png',
  );

  static const neon = AppIconOption(
    id: 'AppIcon-Neon',
    name: 'Neon Lime',
    subtitle: 'Signature LaterBox lime',
    assetPath: 'assets/branding/icons/icon_neon.png',
  );

  static const emerald = AppIconOption(
    id: 'AppIcon-Emerald',
    name: 'Emerald Forest',
    subtitle: 'Deep forest green',
    assetPath: 'assets/branding/icons/icon_emerald.png',
  );

  static const sunset = AppIconOption(
    id: 'AppIcon-Sunset',
    name: 'Sunset Coral',
    subtitle: 'Warm coral glow',
    assetPath: 'assets/branding/icons/icon_sunset.png',
  );

  static const monochrome = AppIconOption(
    id: 'AppIcon-Monochrome',
    name: 'Monochrome',
    subtitle: 'Pure OLED black',
    assetPath: 'assets/branding/icons/icon_monochrome.png',
  );

  static const List<AppIconOption> all = [
    defaultIcon,
    dark,
    neon,
    emerald,
    sunset,
    monochrome,
  ];

  static AppIconOption fromId(String? id) {
    return all.firstWhere(
      (opt) => opt.id == id,
      orElse: () => defaultIcon,
    );
  }
}

/// Service that interfaces with the native iOS platform channel to inspect
/// and switch the app's home screen icon.
class AppIconService {
  const AppIconService({
    MethodChannel? channel,
    this.platform,
  })  : _channel = channel ?? const MethodChannel('laterbox/app_icon');

  final MethodChannel _channel;
  final TargetPlatform? platform;

  TargetPlatform get effectivePlatform => platform ?? defaultTargetPlatform;

  /// Whether the current platform and device support alternate app icons.
  Future<bool> isSupported() async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final supported = await _channel.invokeMethod<bool>('supportsAlternateIcons');
      return supported ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Gets the currently active alternate icon name (`null` for default primary).
  Future<String?> getCurrentIconName() async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return null;
    }
    try {
      return await _channel.invokeMethod<String?>('getAlternateIconName');
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Switches the iOS app icon to the specified variant [iconName] (or `null` to reset to default).
  Future<bool> setAlternateIconName(String? iconName) async {
    if (kIsWeb || effectivePlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      final success = await _channel.invokeMethod<bool>(
        'setAlternateIconName',
        {'iconName': iconName},
      );
      return success ?? true;
    } on PlatformException catch (e) {
      debugPrint('[AppIconService] Failed to set alternate icon: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('[AppIconService] Unexpected error setting icon: $e');
      return false;
    }
  }
}
