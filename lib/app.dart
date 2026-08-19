import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/enrichment/enrichment_providers.dart';
import 'features/capture/domain/capture_providers.dart';

class LaterBoxApp extends ConsumerStatefulWidget {
  const LaterBoxApp({super.key});

  @override
  ConsumerState<LaterBoxApp> createState() => _LaterBoxAppState();
}

class _LaterBoxAppState extends ConsumerState<LaterBoxApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(enrichmentCoordinatorProvider);
    });
    _drainPendingShares();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _drainPendingShares();
  }

  void _drainPendingShares() {
    unawaited(_captureAndroidShares());
    unawaited(_importIosShares());
  }

  Future<void> _captureAndroidShares() async {
    try {
      final pending = await ref
          .read(androidShareReceiverProvider)
          .consumePendingShares();
      for (final payload in pending) {
        await ref.read(captureServiceProvider).save(payload);
      }
    } on MissingPluginException {
      // Not running on Android; there is nothing to consume.
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to capture shared item: $error\n$stackTrace');
    }
  }

  Future<void> _importIosShares() async {
    try {
      final receiver = ref.read(iosShareReceiverProvider);
      final pending = await receiver.consumePendingShares();
      if (pending.isEmpty) return;
      for (final payload in pending) {
        await ref.read(captureServiceProvider).save(payload);
      }
      await receiver.clearPending();
    } on MissingPluginException {
      // Not running on iOS; there is nothing to consume.
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to import iOS shares: $error\n$stackTrace');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'LaterBox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
