import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_provider.dart';

class DownloadScreen extends ConsumerStatefulWidget {
  const DownloadScreen({super.key});

  @override
  ConsumerState<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends ConsumerState<DownloadScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _triggerDownload(BuildContext context, String filename) async {
    final messenger = ScaffoldMessenger.of(context);
    final relativeUri = Uri.parse('/downloads/$filename');
    final absoluteUri = Uri.parse('https://laterbox.micorp.pro/downloads/$filename');

    try {
      final launched = await launchUrl(
        relativeUri,
        mode: LaunchMode.platformDefault,
      );
      if (!launched) {
        await launchUrl(
          absoluteUri,
          mode: LaunchMode.externalApplication,
        );
      }
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Download started for $filename'),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {
      try {
        await launchUrl(
          absoluteUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Could not open download link: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 860;
    final isMobile = width < 600;

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            children: [
              _DownloadHeader(isDesktop: isDesktop),
              _DownloadHeroSection(isDesktop: isDesktop, isMobile: isMobile),
              _WindowsDownloadSection(
                isDesktop: isDesktop,
                isMobile: isMobile,
                onDownloadExe: () => _triggerDownload(context, 'laterbox-windows-setup.exe'),
                onDownloadZip: () => _triggerDownload(context, 'laterbox-windows-x64.zip'),
              ),
              _RoadmapSection(isDesktop: isDesktop, isMobile: isMobile),
              _AvailablePlatformsSection(isDesktop: isDesktop, isMobile: isMobile),
              _QuickInstallGuide(isDesktop: isDesktop, isMobile: isMobile),
              _DownloadFaqSection(isDesktop: isDesktop, isMobile: isMobile),
              _DownloadFooter(isDesktop: isDesktop, isMobile: isMobile),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadHeader extends ConsumerWidget {
  const _DownloadHeader({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider).asData?.value;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isMobile ? 32 : 36,
                        height: isMobile ? 32 : 36,
                        padding: const EdgeInsets.all(2),
                        child: Image.asset(
                          'assets/branding/laterbox-icon.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.bookmark_rounded,
                            color: theme.colorScheme.primary,
                            size: isMobile ? 22 : 26,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'laterbox',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          fontSize: isMobile ? 18 : 22,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isDesktop)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NavTextButton(
                      label: 'Home',
                      onTap: () => context.go('/'),
                    ),
                    const SizedBox(width: 16),
                    _NavTextButton(
                      label: 'Features',
                      onTap: () => context.go('/'),
                    ),
                    const SizedBox(width: 16),
                    _NavTextButton(
                      label: 'Extension',
                      onTap: () => context.go('/extension/connect'),
                    ),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!(auth?.isAuthenticated ?? false)) ...[
                    TextButton(
                      onPressed: () => context.go('/login'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 16,
                          vertical: isMobile ? 8 : 12,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 13 : 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    SizedBox(width: isMobile ? 6 : 10),
                  ],
                  FilledButton(
                    onPressed: () => context.go('/inbox'),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 20,
                        vertical: isMobile ? 8 : 12,
                      ),
                      minimumSize: Size(0, isMobile ? 36 : 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: isMobile ? 16 : 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          auth?.isAuthenticated ?? false
                              ? 'Open Inbox'
                              : 'Launch App',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: isMobile ? 13 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTextButton extends StatefulWidget {
  const _NavTextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_NavTextButton> createState() => _NavTextButtonState();
}

class _NavTextButtonState extends State<_NavTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _hovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadHeroSection extends StatelessWidget {
  const _DownloadHeroSection({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : (isDesktop ? 64 : 32),
        isMobile ? 32 : 56,
        isMobile ? 20 : (isDesktop ? 64 : 32),
        isMobile ? 24 : 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.devices_rounded,
                      size: isMobile ? 14 : 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Universal Save-For-Later Apps',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: isMobile ? 12 : 13,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Get laterbox for your device',
                textAlign: TextAlign.center,
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: isMobile ? -0.5 : -1.5,
                  fontSize: isMobile ? 28 : (isDesktop ? 48 : 36),
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enjoy instant offline-first bookmarks, AI summaries, and hotkey captures. Download the standalone Windows installer now, and check our roadmap for upcoming mobile and desktop bundles.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.5,
                  fontSize: isMobile ? 14 : 17,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WindowsDownloadSection extends StatelessWidget {
  const _WindowsDownloadSection({
    required this.isDesktop,
    required this.isMobile,
    required this.onDownloadExe,
    required this.onDownloadZip,
  });

  final bool isDesktop;
  final bool isMobile;
  final VoidCallback onDownloadExe;
  final VoidCallback onDownloadZip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Container(
          margin: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 16,
          ),
          padding: EdgeInsets.all(isMobile ? 20 : 36),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0078D4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFF0078D4).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.desktop_windows_rounded,
                      size: 36,
                      color: Color(0xFF0078D4),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Laterbox for Windows',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                fontSize: isMobile ? 20 : 24,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27C93F).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: const Color(0xFF27C93F).withValues(alpha: 0.4),
                                ),
                              ),
                              child: const Text(
                                'AVAILABLE NOW',
                                style: TextStyle(
                                  color: Color(0xFF1E822E),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Version 1.0.0 • 64-bit Architecture (x64) • Windows 10 & 11',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 20),
              Text(
                'Windows Desktop Features',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: const [
                  _FeaturePill(
                    icon: Icons.flash_on_rounded,
                    label: 'Offline SQLite Database Engine',
                  ),
                  _FeaturePill(
                    icon: Icons.keyboard_rounded,
                    label: 'Global Quick Capture (Ctrl+Shift+S)',
                  ),
                  _FeaturePill(
                    icon: Icons.system_update_alt_rounded,
                    label: 'Clean Inno Setup Installer & Uninstaller',
                  ),
                  _FeaturePill(
                    icon: Icons.power_settings_new_rounded,
                    label: 'Background System Tray & Auto-Startup',
                  ),
                  _FeaturePill(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Per-User Install (No Admin Rights Needed)',
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: onDownloadExe,
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Download Installer (.exe) • 12 MB'),
                    style: FilledButton.styleFrom(
                      elevation: 0,
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 26,
                        vertical: 16,
                      ),
                      minimumSize: Size(isMobile ? double.infinity : 0, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 0 : 16,
                    height: isMobile ? 12 : 0,
                  ),
                  OutlinedButton.icon(
                    onPressed: onDownloadZip,
                    icon: const Icon(Icons.folder_zip_rounded, size: 20),
                    label: const Text('Download Portable (.zip) • 14 MB'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 16,
                      ),
                      minimumSize: Size(isMobile ? double.infinity : 0, 50),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Safe, standalone installer. No telemetry or bloatware.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoadmapSection extends StatelessWidget {
  const _RoadmapSection({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final upcomingPlatforms = [
      (
        icon: Icons.desktop_mac_rounded,
        title: 'macOS',
        subtitle: 'Apple Silicon (M1–M4) & Intel',
        status: 'COMING SOON',
        statusColor: Colors.orange,
        format: '.dmg / .pkg Installer',
        features: 'Menu bar tray item, native Spotlight-style shortcut, Safari share extension.',
      ),
      (
        icon: Icons.terminal_rounded,
        title: 'Linux',
        subtitle: 'Ubuntu, Fedora, Arch & Debian',
        status: 'COMING SOON',
        statusColor: Colors.orange,
        format: '.deb / AppImage / Flatpak',
        features: 'X11 & Wayland tray support, system shortcut daemon, ultra-lightweight.',
      ),
      (
        icon: Icons.phone_iphone_rounded,
        title: 'iOS',
        subtitle: 'iPhone & iPad (iOS 16+)',
        status: 'IN DEVELOPMENT',
        statusColor: Colors.purple,
        format: 'App Store & TestFlight',
        features: '1-tap iOS Share Sheet extension, offline cache, dynamic home widgets.',
      ),
      (
        icon: Icons.android_rounded,
        title: 'Android',
        subtitle: 'Android 9.0+ (API 28+)',
        status: 'IN DEVELOPMENT',
        statusColor: Colors.purple,
        format: 'Google Play & Direct APK',
        features: 'System share target, Quick Settings capture tile, background cloud sync.',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
        vertical: 48,
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'ROADMAP & UPCOMING PLATFORMS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'More platforms coming soon',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  fontSize: isMobile ? 24 : 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We are building dedicated native clients for all major operating systems.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 36),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isMobile ? 1 : (isDesktop ? 2 : 2),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: isMobile ? 180 : 190,
                ),
                itemCount: upcomingPlatforms.length,
                itemBuilder: (context, index) {
                  final p = upcomingPlatforms[index];
                  return Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                p.icon,
                                size: 24,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  Text(
                                    p.subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: p.statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: p.statusColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                p.status,
                                style: TextStyle(
                                  color: p.statusColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Package: ${p.format}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          p.features,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailablePlatformsSection extends StatelessWidget {
  const _AvailablePlatformsSection({
    required this.isDesktop,
    required this.isMobile,
  });

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              Text(
                'Available right now on Web & Extensions',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  fontSize: isMobile ? 20 : 26,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Access your saved bookmarks immediately from any browser without installing an executable.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.language_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Laterbox Web Application',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Works smoothly in Chrome, Edge, Safari, Firefox, and mobile web browsers with offline SQLite WASM persistence.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          FilledButton.icon(
                            onPressed: () => context.go('/inbox'),
                            icon: const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('Launch Web App'),
                            style: FilledButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 0 : 16,
                    height: isMobile ? 16 : 0,
                  ),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.extension_rounded,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Chrome & Browser Extension',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Save any tab, article, or YouTube video with one click directly into your Laterbox account with real-time sync.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 20),
                          OutlinedButton.icon(
                            onPressed: () => context.go('/extension/connect'),
                            icon: const Icon(Icons.cable_rounded, size: 16),
                            label: const Text('Connect Extension'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickInstallGuide extends StatelessWidget {
  const _QuickInstallGuide({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final steps = [
      (
        step: '1',
        title: 'Download the Setup Executable',
        desc: 'Click "Download Installer (.exe)" to get the latest 12 MB installer package.',
      ),
      (
        step: '2',
        title: 'Run the Modern Setup Wizard',
        desc: 'Double-click the downloaded setup. It installs safely to your user directory without needing admin rights.',
      ),
      (
        step: '3',
        title: 'Capture Instantly with Shortcuts',
        desc: 'Launch Laterbox from your desktop or Start Menu. Press Ctrl+Shift+S anytime to save links and notes!',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
        vertical: 48,
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              Text(
                'How to install Laterbox on Windows',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 20 : 26,
                ),
              ),
              const SizedBox(height: 32),
              Flex(
                direction: isDesktop ? Axis.horizontal : Axis.vertical,
                children: steps.map((s) {
                  final card = Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 8 : 0,
                      vertical: isDesktop ? 0 : 8,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            s.step,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          s.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.desc,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  );
                  return isDesktop ? Expanded(child: card) : card;
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadFaqSection extends StatelessWidget {
  const _DownloadFaqSection({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final faqs = [
      (
        q: 'Do I need Administrator privileges to install Laterbox on Windows?',
        a: 'No. Laterbox installs into your user application directory by default, requiring no admin permissions or UAC prompts.',
      ),
      (
        q: 'Can I use Laterbox completely offline?',
        a: 'Yes! Laterbox is built with an offline-first architecture using SQLite. All your links, tags, and notes are cached locally.',
      ),
      (
        q: 'How do I capture links while browsing?',
        a: 'You can use the Laterbox Chrome Extension, copy links to clipboard, or press the global shortcut Ctrl+Shift+S on Windows.',
      ),
      (
        q: 'When will the macOS and mobile apps be ready?',
        a: 'Native macOS, iOS, and Android clients are currently in active testing and will be released in upcoming updates.',
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : (isDesktop ? 64 : 24),
        vertical: 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: Column(
            children: [
              Text(
                'Frequently Asked Questions',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 20 : 26,
                ),
              ),
              const SizedBox(height: 28),
              ...faqs.map(
                (faq) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 18,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              faq.q,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 26),
                        child: Text(
                          faq.a,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadFooter extends StatelessWidget {
  const _DownloadFooter({required this.isDesktop, required this.isMobile});

  final bool isDesktop;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 48,
        36,
        isMobile ? 20 : 48,
        24,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '© ${DateTime.now().year} laterbox. All rights reserved.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: isMobile ? 12 : 0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Home'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/inbox'),
                        child: const Text('Inbox'),
                      ),
                      TextButton(
                        onPressed: () => context.go('/extension/connect'),
                        child: const Text('Extension'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
