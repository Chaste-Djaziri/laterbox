import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'web_reloader.dart';

class WebUpdateState {
  const WebUpdateState({
    this.hasUpdate = false,
    this.isDismissed = false,
    this.isReloading = false,
  });

  final bool hasUpdate;
  final bool isDismissed;
  final bool isReloading;

  bool get shouldShowBanner => hasUpdate && !isDismissed;

  WebUpdateState copyWith({
    bool? hasUpdate,
    bool? isDismissed,
    bool? isReloading,
  }) {
    return WebUpdateState(
      hasUpdate: hasUpdate ?? this.hasUpdate,
      isDismissed: isDismissed ?? this.isDismissed,
      isReloading: isReloading ?? this.isReloading,
    );
  }
}

class WebUpdateNotifier extends StateNotifier<WebUpdateState> {
  WebUpdateNotifier({
    http.Client? client,
    bool? enabled,
    bool autoStart = true,
  })  : _client = client ?? http.Client(),
        _enabled = enabled ?? kIsWeb,
        super(const WebUpdateState()) {
    if (_enabled && autoStart) {
      _init();
    }
  }

  final http.Client _client;
  final bool _enabled;
  Timer? _pollingTimer;
  String? _initialPayload;
  bool _initialized = false;

  void _init() {
    unawaited(checkForUpdate(isInitial: true));
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => checkForUpdate(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _client.close();
    super.dispose();
  }

  Future<void> checkForUpdate({bool isInitial = false}) async {
    if (!_enabled) return;
    try {
      final uri = Uri.parse('/version.json').replace(
        queryParameters: {
          '_t': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      );
      final response = await _client.get(
        uri,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final payload = response.body.trim();
        if (payload.isNotEmpty) {
          if (!_initialized || isInitial) {
            _initialPayload = payload;
            _initialized = true;
          } else if (_initialPayload != null && payload != _initialPayload) {
            if (!state.hasUpdate) {
              state = state.copyWith(hasUpdate: true, isDismissed: false);
            }
          }
        }
      }
    } catch (_) {
      // Ignore network errors during polling
    }
  }

  void dismiss() {
    state = state.copyWith(isDismissed: true);
  }

  Future<void> reloadAndApplyUpdate() async {
    state = state.copyWith(isReloading: true);
    await reloadWebWithoutCache();
  }
}

final webUpdateProvider =
    StateNotifierProvider<WebUpdateNotifier, WebUpdateState>((ref) {
  return WebUpdateNotifier();
});
