class MediaEmbedInfo {
  const MediaEmbedInfo({
    required this.embedUrl,
    required this.provider,
    required this.originalUrl,
    this.videoId,
    this.aspectRatio = 16 / 9,
    this.isAudio = false,
    this.lyricsApiUrl,
    this.songSlug,
  });

  final String embedUrl;
  final String provider;
  final String originalUrl;
  final String? videoId;
  final double aspectRatio;
  final bool isAudio;

  /// Lyrica public lyrics API endpoint (non-null for Lyrica embeds)
  final String? lyricsApiUrl;

  /// Lyrica song slug used for both embed + lyrics API
  final String? songSlug;

  bool get hasLyrics => lyricsApiUrl != null;
}

class MediaEmbedHelper {
  static MediaEmbedInfo? parse(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return null;
    final url = rawUrl.trim();
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final host = uri.host.toLowerCase();
    final path = uri.path;

    // 1. YouTube
    if (host.contains('youtube.com') || host.contains('youtu.be')) {
      String? videoId;
      bool isShort = false;

      if (host.contains('youtu.be')) {
        videoId = path.replaceAll('/', '').trim();
      } else if (path.startsWith('/shorts/')) {
        videoId = path.replaceFirst('/shorts/', '').replaceAll('/', '').trim();
        isShort = true;
      } else if (path.startsWith('/embed/')) {
        videoId = path.replaceFirst('/embed/', '').replaceAll('/', '').trim();
      } else if (uri.queryParameters.containsKey('v')) {
        videoId = uri.queryParameters['v']?.trim();
      }

      if (videoId != null && videoId.isNotEmpty) {
        return MediaEmbedInfo(
          embedUrl: 'https://www.youtube-nocookie.com/embed/$videoId?autoplay=0&rel=0',
          provider: 'YouTube',
          originalUrl: url,
          videoId: videoId,
          aspectRatio: isShort ? 9 / 16 : 16 / 9,
        );
      }
    }

    // 2. Vimeo
    if (host.contains('vimeo.com')) {
      final match = RegExp(r'vimeo\.com/(?:video/)?([0-9]+)').firstMatch(url);
      final videoId = match?.group(1);
      if (videoId != null && videoId.isNotEmpty) {
        return MediaEmbedInfo(
          embedUrl: 'https://player.vimeo.com/video/$videoId',
          provider: 'Vimeo',
          originalUrl: url,
          videoId: videoId,
          aspectRatio: 16 / 9,
        );
      }
    }

    // 3. Spotify
    if (host.contains('spotify.com')) {
      final match = RegExp(r'open\.spotify\.com/(track|album|playlist|episode)/([a-zA-Z0-9]+)').firstMatch(url);
      if (match != null) {
        final type = match.group(1);
        final id = match.group(2);
        return MediaEmbedInfo(
          embedUrl: 'https://open.spotify.com/embed/$type/$id',
          provider: 'Spotify',
          originalUrl: url,
          aspectRatio: type == 'track' ? 16 / 5 : 16 / 9,
          isAudio: true,
        );
      }
    }

    // 4. SoundCloud
    if (host.contains('soundcloud.com')) {
      if (path.length > 3 && path.contains('/')) {
        final encoded = Uri.encodeComponent(url);
        return MediaEmbedInfo(
          embedUrl: 'https://w.soundcloud.com/player/?url=$encoded&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true',
          provider: 'SoundCloud',
          originalUrl: url,
          aspectRatio: 16 / 6,
          isAudio: true,
        );
      }
    }

    // 5. Lyrica (lyricarw.com)
    if (host.contains('lyricarw.com')) {
      // Matches: lyricarw.com/songs/slug  OR  lyricarw.com/embed/song/slug
      final embedMatch = RegExp(r'lyricarw\.com/(?:embed/song|songs)/([a-zA-Z0-9_-]+)').firstMatch(url);
      final slug = embedMatch?.group(1);
      if (slug != null && slug.isNotEmpty) {
        return MediaEmbedInfo(
          embedUrl: 'https://lyricarw.com/embed/song/$slug',
          provider: 'Lyrica',
          originalUrl: url,
          songSlug: slug,
          aspectRatio: 16 / 2.4, // ~152px compact player bar
          isAudio: true,
          lyricsApiUrl: 'https://lyricarw.com/api/public/songs/$slug/lyrics',
        );
      }
    }

    return null;
  }
}
