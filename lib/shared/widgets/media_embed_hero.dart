import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../utils/media_embed_helper.dart';

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
    // Lyrica: render compact player + optional lyrics panel (no fixed aspect ratio)
    if (embedInfo.provider == 'Lyrica') {
      return _LyricaEmbed(embedInfo: embedInfo);
    }

    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isCompactScreen = width < 600;
    final effectiveAspectRatio =
        isCompactScreen ? 16 / 9 : embedInfo.aspectRatio;

    final Widget playerWidget = _NativeEmbedPlayerCard(
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

// ─────────────────────────────────────────────────────────────────────────────
// Lyrica embed: responsive 152px player + expandable lyrics panel
// ─────────────────────────────────────────────────────────────────────────────
class _LyricaEmbed extends StatefulWidget {
  const _LyricaEmbed({required this.embedInfo});

  final MediaEmbedInfo embedInfo;

  @override
  State<_LyricaEmbed> createState() => _LyricaEmbedState();
}

class _LyricaEmbedState extends State<_LyricaEmbed> {
  static const _lyricaColor = Color(0xFF7C3AED);

  bool _showLyrics = false;
  bool _loadingLyrics = false;
  String? _lyricsError;
  List<_LyricLine> _lines = [];
  String? _plainLyrics;

  Future<void> _fetchLyrics() async {
    if (_loadingLyrics || _lines.isNotEmpty) return;
    setState(() => _loadingLyrics = true);

    try {
      final uri = Uri.parse(widget.embedInfo.lyricsApiUrl!);
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final synced = data['synced'] as List<dynamic>?;
        if (synced != null && synced.isNotEmpty) {
          _lines = synced
              .map((e) => _LyricLine(
                    time: (e['time'] as num?)?.toDouble() ?? 0,
                    text: (e['text'] as String?) ?? '',
                  ))
              .toList();
        }
        _plainLyrics =
            (data['plain'] as String?) ?? (data['lyrics'] as String?);
      } else {
        _lyricsError = 'Could not load lyrics (${resp.statusCode})';
      }
    } catch (e) {
      _lyricsError = 'Failed to load lyrics';
    } finally {
      if (mounted) setState(() => _loadingLyrics = false);
    }
  }

  void _copyLyrics() {
    final text = _lines.isNotEmpty
        ? _lines.map((l) => l.text).join('\n')
        : _plainLyrics ?? '';
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lyrics copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Compact player bar ────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E1230), const Color(0xFF2D1B5E)]
                  : [const Color(0xFF4C1D95), const Color(0xFF7C3AED)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.08,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.music_note_rounded,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatSlug(widget.embedInfo.songSlug),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'LYRICA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Music · Lyrics Available',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _PlayerButton(
                          icon: Icons.open_in_new_rounded,
                          label: 'Open',
                          onTap: () async {
                            final uri =
                                Uri.parse(widget.embedInfo.originalUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          },
                        ),
                        if (widget.embedInfo.hasLyrics) ...[
                          const SizedBox(height: 6),
                          _PlayerButton(
                            icon: Icons.lyrics_rounded,
                            label: _showLyrics ? 'Hide' : 'Lyrics',
                            highlight: _showLyrics,
                            onTap: () async {
                              if (!_showLyrics) await _fetchLyrics();
                              setState(() => _showLyrics = !_showLyrics);
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Lyrics panel ──────────────────────────────────────────────────
        if (_showLyrics) ...[
          const SizedBox(height: 8),
          _LyricsPanel(
            lines: _lines,
            plainLyrics: _plainLyrics,
            loading: _loadingLyrics,
            error: _lyricsError,
            accentColor: _lyricaColor,
            onCopy: _copyLyrics,
          ),
        ],
      ],
    );
  }

  String _formatSlug(String? slug) {
    if (slug == null || slug.isEmpty) return 'Lyrica Song';
    return slug
        .replaceAll('-', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

class _PlayerButton extends StatelessWidget {
  const _PlayerButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: highlight ? 0.5 : 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LyricLine {
  const _LyricLine({required this.time, required this.text});
  final double time;
  final String text;
}

class _LyricsPanel extends StatelessWidget {
  const _LyricsPanel({
    required this.lines,
    required this.plainLyrics,
    required this.loading,
    required this.error,
    required this.accentColor,
    required this.onCopy,
  });

  final List<_LyricLine> lines;
  final String? plainLyrics;
  final bool loading;
  final String? error;
  final Color accentColor;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.lyrics_rounded, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  'Lyrics',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                if (!loading &&
                    error == null &&
                    (lines.isNotEmpty || plainLyrics != null))
                  GestureDetector(
                    onTap: onCopy,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.copy_rounded,
                              size: 11, color: accentColor),
                          const SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    if (loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          error!,
          style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
        ),
      );
    }

    final displayLines = lines.isNotEmpty
        ? lines.map((l) => l.text).toList()
        : (plainLyrics?.split('\n') ?? []);

    if (displayLines.isEmpty) {
      return Text(
        'No lyrics available.',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          fontSize: 12,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: displayLines
          .map(
            (line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                line.isEmpty ? ' ' : line,
                style: TextStyle(
                  color: line.isEmpty
                      ? Colors.transparent
                      : theme.colorScheme.onSurface,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  height: 1.6,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Existing player card for YouTube / Vimeo / Spotify / SoundCloud
// ─────────────────────────────────────────────────────────────────────────────
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
                    Icon(getProviderIcon(), size: 14, color: Colors.white),
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
