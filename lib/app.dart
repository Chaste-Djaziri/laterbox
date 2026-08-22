import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/desktop/desktop_actions.dart';
import 'core/desktop/desktop_capabilities.dart';
import 'core/desktop/desktop_providers.dart';
import 'core/enrichment/enrichment_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/scroll_behavior.dart';
import 'core/web/web_update_banner.dart';
import 'core/web/web_update_service.dart';
import 'features/attachments/presentation/attachment_providers.dart';
import 'features/attachments/domain/attachment_import_result.dart';
import 'features/capture/domain/capture_providers.dart';
import 'features/capture/domain/capture_payload.dart';
import 'features/capture/domain/native_share_payload.dart';
import 'features/quick_capture/presentation/quick_capture_screen.dart';

class LaterBoxApp extends ConsumerStatefulWidget {
  const LaterBoxApp({super.key});

  @override
  ConsumerState<LaterBoxApp> createState() => _LaterBoxAppState();
}

class _LaterBoxAppState extends ConsumerState<LaterBoxApp>
    with WidgetsBindingObserver {
  bool _drainingShares = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(enrichmentCoordinatorProvider);
    });
    unawaited(_cleanAttachmentOrphans());
    _drainPendingShares();
    _initDesktop();
    _syncDesktopIconTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _drainPendingShares();
      if (kIsWeb) {
        ref.read(webUpdateProvider.notifier).checkForUpdate();
      }
    }
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    _syncDesktopIconTheme();
  }

  void _syncDesktopIconTheme() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      const MethodChannel('pro.micorp.laterbox/desktop_icon').invokeMethod<void>(
        'updateIcon',
        {'isDark': brightness == Brightness.dark},
      ).catchError((_) => null);
    }
  }

  void _initDesktop() {
    if (!isDesktopSupported) return;
    unawaited(_initializeDesktop());
  }

  Future<void> _cleanAttachmentOrphans() async {
    try {
      await ref.read(attachmentStartupProvider.future);
    } on Object catch (error, stackTrace) {
      debugPrint('[LaterBox Attachments] orphan cleanup failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> _initializeDesktop() async {
    try {
      await ref.read(desktopActionsProvider).applyStartup();
    } on Object catch (error, stackTrace) {
      debugPrint('[LaterBox Desktop] desktop initialization FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _drainPendingShares() {
    if (_drainingShares) return;
    _drainingShares = true;
    unawaited(_drainNativeShares());
  }

  Future<void> _drainNativeShares() async {
    try {
      await _captureAndroidShares();
      await _importAppleShares();
    } finally {
      _drainingShares = false;
    }
  }

  Future<void> _captureAndroidShares() async {
    try {
      final pending = await ref
          .read(androidShareReceiverProvider)
          .consumePendingShares();
      for (final payload in pending) {
        if (await _importNativeShare(payload, CaptureSource.androidShare)) {
          await ref.read(androidShareReceiverProvider).acknowledge([
            payload.id,
          ]);
        }
      }
    } on MissingPluginException {
      // Not running on Android; there is nothing to consume.
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to capture shared item: $error\n$stackTrace');
    }
  }

  Future<void> _importAppleShares() async {
    try {
      final receiver = ref.read(iosShareReceiverProvider);
      final pending = await receiver.consumePendingShares();
      if (pending.isEmpty) return;
      for (final payload in pending) {
        final source = Platform.isMacOS
            ? CaptureSource.macosShare
            : CaptureSource.iosShare;
        if (await _importNativeShare(payload, source)) {
          await receiver.acknowledge([payload.id]);
        }
      }
    } on MissingPluginException {
      // Not running on iOS; there is nothing to consume.
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to import Apple shares: $error\n$stackTrace');
    }
  }

  Future<bool> _importNativeShare(
    NativeSharePayload payload,
    CaptureSource source,
  ) async {
    final filePaths = List<String>.from(payload.filePaths);
    final text = payload.text;
    if (text != null && text.isNotEmpty && filePaths.isEmpty) {
      final extracted = NativeSharePayload.extractFilePathFromUri(text);
      if (extracted != null && File(extracted).existsSync()) {
        filePaths.add(extracted);
      }
    }

    if (filePaths.isEmpty) {
      if (text == null) return true;
      await ref
          .read(captureServiceProvider)
          .save(
            CapturePayload.fromValue(
              text,
              id: payload.id,
              createdAt: payload.createdAt,
              source: source,
            ),
          );
      return true;
    }

    final service = await ref.read(attachmentImportServiceProvider.future);
    final result = await service.importFiles(
      sourcePaths: filePaths,
      text: filePaths.length == payload.filePaths.length ? text : null,
      itemId: payload.id,
    );
    if (result.saved) return true;
    return !result.failures.any(
      (failure) => switch (failure.code) {
        AttachmentImportFailureCode.databaseFailed ||
        AttachmentImportFailureCode.copyFailed ||
        AttachmentImportFailureCode.verificationFailed ||
        AttachmentImportFailureCode.unreadable ||
        AttachmentImportFailureCode.sourceChanged => true,
        AttachmentImportFailureCode.unsupportedType ||
        AttachmentImportFailureCode.tooLarge ||
        AttachmentImportFailureCode.emptyFile ||
        AttachmentImportFailureCode.mimeMismatch => false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quickCaptureActive = ref.watch(
      quickCaptureControllerProvider.select(
        (controller) => controller.isActive,
      ),
    );
    return MaterialApp.router(
      title: 'laterbox',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
      scrollBehavior: const LaterBoxScrollBehavior(),
      builder: (context, child) {
        final content = quickCaptureActive
            ? const Material(child: QuickCaptureScreen())
            : (child ?? const SizedBox.shrink());
        return WebUpdateBannerOverlay(child: content);
      },
    );
  }
}
