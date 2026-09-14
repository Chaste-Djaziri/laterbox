import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

const iosAppStoreId = '6804139119';
const iosAppStoreUrl =
    'https://apps.apple.com/us/app/laterbox-save-for-later/id6804139119';

class IosAppStoreUpdateState {
  const IosAppStoreUpdateState({
    this.latestVersion,
    this.storeUrl = iosAppStoreUrl,
    this.dismissed = false,
  });

  final String? latestVersion;
  final String storeUrl;
  final bool dismissed;

  bool get shouldShow => latestVersion != null && !dismissed;

  IosAppStoreUpdateState copyWith({
    String? latestVersion,
    String? storeUrl,
    bool? dismissed,
  }) {
    return IosAppStoreUpdateState(
      latestVersion: latestVersion ?? this.latestVersion,
      storeUrl: storeUrl ?? this.storeUrl,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

class IosAppStoreUpdateNotifier extends StateNotifier<IosAppStoreUpdateState> {
  IosAppStoreUpdateNotifier({
    http.Client? client,
    Future<String> Function()? installedVersion,
    bool? enabled,
    bool autoStart = true,
  }) : _client = client ?? http.Client(),
       _installedVersion = installedVersion ?? _readInstalledVersion,
       _enabled =
           enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS),
       super(const IosAppStoreUpdateState()) {
    if (_enabled && autoStart) unawaited(checkForUpdate());
  }

  final http.Client _client;
  final Future<String> Function() _installedVersion;
  final bool _enabled;
  bool _checking = false;

  static Future<String> _readInstalledVersion() async {
    return (await PackageInfo.fromPlatform()).version;
  }

  Future<void> checkForUpdate({bool force = false}) async {
    if (!_enabled || _checking || (state.dismissed && !force)) return;
    if (force) state = const IosAppStoreUpdateState();
    _checking = true;
    try {
      final installedVersion = await _installedVersion();
      final response = await _client
          .get(
            Uri.https('itunes.apple.com', '/lookup', {
              'id': iosAppStoreId,
              'country': 'us',
            }),
            headers: const {'Cache-Control': 'no-cache'},
          )
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      final results = decoded is Map ? decoded['results'] : null;
      if (results is! List || results.isEmpty || results.first is! Map) return;
      final result = results.first as Map;
      final latestVersion = result['version'] as String?;
      final storeUrl = result['trackViewUrl'] as String?;
      if (latestVersion == null ||
          !isVersionNewer(latestVersion, installedVersion)) {
        return;
      }
      state = state.copyWith(
        latestVersion: latestVersion,
        storeUrl: storeUrl ?? iosAppStoreUrl,
      );
    } catch (_) {
      // A failed check must never block normal app use.
    } finally {
      _checking = false;
    }
  }

  void dismiss() => state = state.copyWith(dismissed: true);

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}

bool isVersionNewer(String available, String installed) {
  List<int> parse(String value) => value
      .split('.')
      .map((part) => int.tryParse(RegExp(r'^\d+').stringMatch(part) ?? '') ?? 0)
      .toList();

  final availableParts = parse(available);
  final installedParts = parse(installed);
  final length = availableParts.length > installedParts.length
      ? availableParts.length
      : installedParts.length;
  for (var index = 0; index < length; index += 1) {
    final next = index < availableParts.length ? availableParts[index] : 0;
    final current = index < installedParts.length ? installedParts[index] : 0;
    if (next != current) return next > current;
  }
  return false;
}

final iosAppStoreUpdateProvider =
    StateNotifierProvider<IosAppStoreUpdateNotifier, IosAppStoreUpdateState>(
      (ref) => IosAppStoreUpdateNotifier(),
    );
