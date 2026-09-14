import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/desktop/desktop_actions.dart';
import 'core/billing/billing_providers.dart';
import 'core/desktop/desktop_capabilities.dart';
import 'core/desktop/desktop_providers.dart';
import 'core/desktop/macos_companion.dart';
import 'core/enrichment/enrichment_providers.dart';
import 'core/ios/ios_app_store_update_overlay.dart';
import 'core/ios/ios_app_store_update_service.dart';
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
import 'features/capture/presentation/ios_clipboard_capture_overlay.dart';
import 'features/quick_capture/presentation/quick_capture_screen.dart';

class LaterBoxApp extends ConsumerStatefulWidget {
  const LaterBoxApp({super.key});

  @override
  ConsumerState<LaterBoxApp> createState() => _LaterBoxAppState();
}

class _LaterBoxAppState extends ConsumerState<LaterBoxApp>
    with WidgetsBindingObserver {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _appLinkSubscription;
  StreamSubscription<void>? _shareAvailableSubscription;
  Timer? _billingRefreshTimer;
  bool _drainingShares = false;
  final Set<String> _inFlightShareIds = {};
  final Set<String> _processedShareIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleAppLink,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('[LaterBox] app link failed: $error');
      },
    );
    _shareAvailableSubscription = ref
        .read(iosShareReceiverProvider)
        .onShareAvailable
        .listen((_) {
      _drainPendingShares();
    });
    ref.listenManual(entitlementProvider, (_, next) {
      next.whenData((entitlement) {
        unawaited(
          MacOSCompanion.setProAutomationEnabled(entitlement.hasProAccess),
        );
        if (entitlement.hasProAccess) {
          _billingRefreshTimer?.cancel();
          _drainPendingShares();
        }
      });
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(enrichmentCoordinatorProvider);
        _drainPendingShares();
      }
    });
    unawaited(_cleanAttachmentOrphans());
    _drainPendingShares();
    _initDesktop();
    _syncDesktopIconTheme();
  }

  @override
  void dispose() {
    _appLinkSubscription?.cancel();
    _shareAvailableSubscription?.cancel();
    _billingRefreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _handleAppLink(Uri uri) {
    if (uri.scheme == 'laterbox' && uri.host == 'share') {
      final value = uri.queryParameters['value'] ??
          uri.queryParameters['url'] ??
          uri.queryParameters['text'];
      if (value != null && value.isNotEmpty) {
        final id = uri.queryParameters['id'] ??
            DateTime.now().microsecondsSinceEpoch.toString();
        unawaited(
          ref.read(captureServiceProvider).save(
                CapturePayload.fromValue(
                  value,
                  id: id,
                  source: CaptureSource.iosShare,
                ),
              ),
        );
      }
      return;
    }
    if (laterBoxDistribution != 'direct' ||
        uri.scheme != 'laterbox' ||
        uri.host != 'billing' ||
        uri.path != '/complete' ||
        !{'success', 'processing'}.contains(uri.queryParameters['status'])) {
      return;
    }
    final interval = uri.queryParameters['interval'] == 'month'
        ? 'monthly'
        : 'annual';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(entitlementProvider);
      ref
          .read(appRouterProvider)
          .go('/plans?checkout=success&interval=$interval');
      _pollBillingEntitlement();
    });
  }

  void _pollBillingEntitlement() {
    _billingRefreshTimer?.cancel();
    var attempts = 0;
    _billingRefreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      attempts += 1;
      if (!mounted || attempts >= 10) {
        timer.cancel();
        return;
      }
      ref.invalidate(entitlementProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(entitlementProvider);
      _drainPendingShares();
      if (kIsWeb) {
        ref.read(webUpdateProvider.notifier).checkForUpdate();
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        ref.read(iosAppStoreUpdateProvider.notifier).checkForUpdate();
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
      final brightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      const MethodChannel('pro.micorp.laterbox/desktop_icon')
          .invokeMethod<void>('updateIcon', {
            'isDark': brightness == Brightness.dark,
          })
          .catchError((_) => null);
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
      final receiver = ref.read(androidShareReceiverProvider);
      final pending = await receiver.consumePendingShares();
      for (final payload in pending) {
        if (_inFlightShareIds.contains(payload.id)) continue;
        if (_processedShareIds.contains(payload.id)) {
          await receiver.acknowledge([payload.id]);
          continue;
        }
        _inFlightShareIds.add(payload.id);
        try {
          if (await _importNativeShare(payload, CaptureSource.androidShare)) {
            _processedShareIds.add(payload.id);
            await receiver.acknowledge([payload.id]);
          }
        } finally {
          _inFlightShareIds.remove(payload.id);
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
      if (!kIsWeb && Platform.isIOS) {
        final groupOk = await receiver.isAppGroupAvailable();
        if (!groupOk) {
          debugPrint(
            '[LaterBox] WARNING: iOS App Group container is not accessible on this device. '
            'Check App Group entitlements and provisioning profile.',
          );
        }
      }
      final pending = await receiver.consumePendingShares();
      if (pending.isEmpty) return;
      for (final payload in pending) {
        if (_inFlightShareIds.contains(payload.id)) continue;
        if (_processedShareIds.contains(payload.id)) {
          await receiver.acknowledge([payload.id]);
          continue;
        }
        _inFlightShareIds.add(payload.id);
        try {
          final source = Platform.isMacOS
              ? CaptureSource.macosShare
              : CaptureSource.iosShare;
          if (await _importNativeShare(payload, source)) {
            _processedShareIds.add(payload.id);
            await receiver.acknowledge([payload.id]);
            if (Platform.isMacOS) {
              final value =
                  payload.text ??
                  (payload.filePaths.isEmpty
                      ? 'Shared item'
                      : payload.filePaths.first);
              await MacOSCompanion.reportCaptureCompleted(
                id: payload.id,
                title: _shareReceiptTitle(payload),
                value: value,
                kind: _shareReceiptKind(payload),
              );
            }
          } else if (Platform.isMacOS) {
            await MacOSCompanion.reportCaptureFailed(
              id: payload.id,
              message:
                  'Could not import this shared item. Open LaterBox to retry.',
            );
          }
        } finally {
          _inFlightShareIds.remove(payload.id);
        }
      }
    } on MissingPluginException catch (error) {
      debugPrint('[LaterBox] Share method channel not registered: $error');
    } on Object catch (error, stackTrace) {
      debugPrint('Failed to import Apple shares: $error\n$stackTrace');
    }
  }

  String _shareReceiptTitle(NativeSharePayload payload) {
    final text = payload.text?.trim();
    if (text != null && text.isNotEmpty) {
      final uri = Uri.tryParse(text.split(RegExp(r'\s+')).last);
      return uri?.host.isNotEmpty == true
          ? uri!.host
          : text.replaceAll('\n', ' ');
    }
    if (payload.filePaths.isNotEmpty) {
      return File(payload.filePaths.first).uri.pathSegments.last;
    }
    return 'Shared item';
  }

  String _shareReceiptKind(NativeSharePayload payload) {
    if (payload.filePaths.isNotEmpty) {
      final extension = payload.filePaths.first.split('.').last.toLowerCase();
      if (extension == 'pdf') return 'pdf';
      if (const {'jpg', 'jpeg', 'png', 'webp', 'heic'}.contains(extension)) {
        return 'image';
      }
      return 'document';
    }
    final text = payload.text ?? '';
    final hasUrl = RegExp(r'https?://').hasMatch(text);
    return hasUrl && text.split(RegExp(r'\s+')).length > 1
        ? 'highlight'
        : hasUrl
        ? 'link'
        : 'note';
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
        final Widget content;
        if (quickCaptureActive) {
          content = Material(
            child: Overlay(
              initialEntries: [
                OverlayEntry(builder: (context) => const QuickCaptureScreen()),
              ],
            ),
          );
        } else {
          content = child ?? const SizedBox.shrink();
        }
        return IosAppStoreUpdateOverlay(
          child: IosClipboardCaptureOverlay(
            child: WebUpdateBannerOverlay(child: content),
          ),
        );
      },
    );
  }
}
