import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/media_embed_helper.dart';
import 'web_embed_iframe.dart' if (dart.library.io) 'native_embed_stub.dart';

class MediaEmbedHero extends StatelessWidget {
  const MediaEmbedHero({
    super.key,
    required this.embedInfo,
    this.fallbackCoverUrl,
  });

  final MediaEmbedInfo embedInfo;
  final String? fallbackCoverUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompactScreen = width < 600;

    // Desktop 16:9 ratio maintained on phone size with side blank spaces
    final effectiveAspectRatio = isCompactScreen ? 16 / 9 : embedInfo.aspectRatio;

    final Widget playerWidget = kIsWeb
        ? buildWebEmbedIframe(embedInfo.embedUrl)
        : _NativeEmbedPlayerCard(
            embedInfo: embedInfo,
            fallbackCoverUrl: fallbackCoverUrl,
          );

    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      alignment: Alignment.center,
      padding: isCompactScreen
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          : EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800),
        child: AspectRatio(
          aspectRatio: effectiveAspectRatio,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompactScreen ? 12 : 0),
            child: playerWidget,
          ),
        ),
      ),
    );
  }
}

class _NativeEmbedPlayerCard extends StatelessWidget {
  const _NativeEmbedPlayerCard({
    required this.embedInfo,
    this.fallbackCoverUrl,
  });

  final MediaEmbedInfo embedInfo;
  final String? fallbackCoverUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color getProviderColor() {
      switch (embedInfo.provider.toLowerCase()) {
        case 'youtube':
          return const Color(0xFFFF0000);
        case 'vimeo':
          return const Color(0xFF1AB7EA);
        case 'spotify':
          return const Color(0xFF1DB954);
        case 'soundcloud':
          return const Color(0xFFFF5500);
        default:
          return theme.colorScheme.primary;
      }
    }

    IconData getProviderIcon() {
      switch (embedInfo.provider.toLowerCase()) {
        case 'spotify':
        case 'soundcloud':
          return Icons.music_note_rounded;
        default:
          return Icons.play_arrow_rounded;
      }
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (fallbackCoverUrl != null && fallbackCoverUrl!.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                fallbackCoverUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: getProviderColor(),
                shape: const CircleBorder(),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final uri = Uri.parse(embedInfo.originalUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      getProviderIcon(),
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      getProviderIcon(),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Play on ${embedInfo.provider}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
