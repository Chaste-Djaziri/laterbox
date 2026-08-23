import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 800;

    return Scaffold(
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            children: [
              _LandingHeader(
                isDesktop: isDesktop,
                onFeaturesTap: () => _scrollToSection(_featuresKey),
                onHowItWorksTap: () => _scrollToSection(_howItWorksKey),
                onAboutTap: () => _scrollToSection(_aboutKey),
              ),
              _HeroSection(isDesktop: isDesktop),
              _FeaturesSection(
                key: _featuresKey,
                isDesktop: isDesktop,
              ),
              _HowItWorksSection(
                key: _howItWorksKey,
                isDesktop: isDesktop,
              ),
              _AboutSection(
                key: _aboutKey,
                isDesktop: isDesktop,
              ),
              _DownloadTeaserSection(isDesktop: isDesktop),
              _CtaBannerSection(isDesktop: isDesktop),
              _LandingFooter(
                isDesktop: isDesktop,
                onFeaturesTap: () => _scrollToSection(_featuresKey),
                onHowItWorksTap: () => _scrollToSection(_howItWorksKey),
                onAboutTap: () => _scrollToSection(_aboutKey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LandingHeader extends ConsumerWidget {
  const _LandingHeader({
    required this.isDesktop,
    required this.onFeaturesTap,
    required this.onHowItWorksTap,
    required this.onAboutTap,
  });

  final bool isDesktop;
  final VoidCallback onFeaturesTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authStateProvider).asData?.value;
    final width = MediaQuery.sizeOf(context).width;

    final isMobile = width < 600;
    final isDesktopHeader = width >= 860;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.94),
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
              if (isDesktopHeader)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderNavLink(label: 'Features', onTap: onFeaturesTap),
                    const SizedBox(width: 20),
                    _HeaderNavLink(label: 'How It Works', onTap: onHowItWorksTap),
                    const SizedBox(width: 20),
                    _HeaderNavLink(label: 'About', onTap: onAboutTap),
                    const SizedBox(width: 20),
                    _HeaderNavLink(label: 'Download', onTap: () => context.go('/download')),
                  ],
                ),
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
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
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

class _HeaderNavLink extends StatefulWidget {
  const _HeaderNavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeaderNavLink> createState() => _HeaderNavLinkState();
}

class _HeaderNavLinkState extends State<_HeaderNavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.5)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _isHovered
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends ConsumerWidget {
  const _HeroSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 16 : (isDesktop ? 64 : 32),
        isMobile ? 28 : (isDesktop ? 64 : 40),
        isMobile ? 16 : (isDesktop ? 64 : 32),
        isMobile ? 36 : 48,
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: isMobile ? 14 : 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Universal Save-For-Later Memory',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: isMobile ? 11 : 13,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Save anything now.\nRead, watch & organize later.',
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: isMobile ? -0.5 : -1.5,
              height: 1.12,
              fontSize: isMobile ? 28 : (isDesktop ? 52 : 38),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'laterbox automatically enriches your saved links, articles, videos, and notes with key AI summaries, preview cards, favicons, and embedded media players.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
                fontSize: isMobile ? 14 : (isDesktop ? 18 : 16),
              ),
            ),
          ),
          const SizedBox(height: 28),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? 360 : 560),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => context.go('/inbox'),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Get Started Free'),
                  style: FilledButton.styleFrom(
                    elevation: 0,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    minimumSize: Size(isMobile ? double.infinity : 0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => context.go('/download'),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download App'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    minimumSize: Size(isMobile ? double.infinity : 0, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ref.read(guestModeProvider.notifier).state = true;
                    context.go('/inbox');
                  },
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: const Text('Try Guest Mode'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    minimumSize: Size(isMobile ? double.infinity : 0, 46),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 14 : 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                    blurRadius: 28,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5F56),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFBD2E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27C93F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'https://laterbox.dev/inbox',
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isMobile)
                    const Column(
                      children: [
                        _DemoCardMockup(
                          icon: Icons.play_circle_fill_rounded,
                          iconColor: Colors.red,
                          domain: 'youtube.com',
                          title: 'Flutter Desktop 3.29 Complete Guide',
                          tag: 'Video',
                        ),
                        SizedBox(height: 10),
                        _DemoCardMockup(
                          icon: Icons.article_rounded,
                          iconColor: Colors.blue,
                          domain: 'github.com',
                          title: 'Building Universal Extensions with MV3',
                          tag: 'Article',
                        ),
                      ],
                    )
                  else
                    const Row(
                      children: [
                        Expanded(
                          child: _DemoCardMockup(
                            icon: Icons.play_circle_fill_rounded,
                            iconColor: Colors.red,
                            domain: 'youtube.com',
                            title: 'Flutter Desktop 3.29 Complete Guide',
                            tag: 'Video',
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _DemoCardMockup(
                            icon: Icons.article_rounded,
                            iconColor: Colors.blue,
                            domain: 'github.com',
                            title: 'Building Universal Extensions with MV3',
                            tag: 'Article',
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoCardMockup extends StatelessWidget {
  const _DemoCardMockup({
    required this.icon,
    required this.iconColor,
    required this.domain,
    required this.title,
    required this.tag,
  });

  final IconData icon;
  final Color iconColor;
  final String domain;
  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                domain,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;

    final isTablet = width >= 600 && width < 960;
    final isDesktopGrid = width >= 960;

    final features = [
      (
        icon: Icons.extension_rounded,
        title: 'Universal 1-Tap Save',
        description:
            'Save articles, YouTube videos, tweets, and notes instantly via Browser Extensions, iOS, Android, or Desktop.'
      ),
      (
        icon: Icons.psychology_rounded,
        title: 'Smart AI Enrichment',
        description:
            'Extract key summaries, high-res preview covers, structured metadata, and automatically categorize content.'
      ),
      (
        icon: Icons.play_circle_outline_rounded,
        title: 'Native Media Embeds',
        description:
            'Watch YouTube videos, Vimeo streams, and listen to Spotify or SoundCloud audio directly inside laterbox.'
      ),
      (
        icon: Icons.offline_bolt_rounded,
        title: 'Offline-First Storage',
        description:
            'Powered by SQLite local storage. Instant response times with background Supabase cloud sync.'
      ),
      (
        icon: Icons.filter_alt_rounded,
        title: 'Category & Starred Filters',
        description:
            'Filter by Articles, Videos, Music, Notes, or Starred items with live category counts.'
      ),
      (
        icon: Icons.search_rounded,
        title: 'Instant Deep Search',
        description:
            'Find any saved link, quote, domain, or personal note in milliseconds with full-text search.'
      ),
    ];

    Widget buildCard(
      BuildContext context, {
      required IconData icon,
      required String title,
      required String description,
    }) {
      return Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(minHeight: 190),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget content;
    if (isDesktopGrid) {
      content = Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[0].icon,
                    title: features[0].title,
                    description: features[0].description,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[1].icon,
                    title: features[1].title,
                    description: features[1].description,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[2].icon,
                    title: features[2].title,
                    description: features[2].description,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[3].icon,
                    title: features[3].title,
                    description: features[3].description,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[4].icon,
                    title: features[4].title,
                    description: features[4].description,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: buildCard(
                    context,
                    icon: features[5].icon,
                    title: features[5].title,
                    description: features[5].description,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (isTablet) {
      content = Column(
        children: [
          for (var i = 0; i < features.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 20),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: buildCard(
                      context,
                      icon: features[i].icon,
                      title: features[i].title,
                      description: features[i].description,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: buildCard(
                      context,
                      icon: features[i + 1].icon,
                      title: features[i + 1].title,
                      description: features[i + 1].description,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    } else {
      content = Column(
        children: [
          for (var i = 0; i < features.length; i++) ...[
            if (i > 0) const SizedBox(height: 16),
            buildCard(
              context,
              icon: features[i].icon,
              title: features[i].title,
              description: features[i].description,
            ),
          ],
        ],
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktopGrid ? 64 : 24,
        vertical: 60,
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Column(
        children: [
          Text(
            'Everything you need to capture & remember',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              fontSize: isDesktopGrid ? 36 : 26,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Designed for speed, clarity, and focus across all your devices.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: content,
          ),
        ],
      ),
    );
  }
}

class _HowItWorksSection extends StatelessWidget {
  const _HowItWorksSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final steps = [
      (
        step: '01',
        title: 'Capture Anywhere',
        desc: 'Save any link or note with 1 click from your browser or phone.'
      ),
      (
        step: '02',
        title: 'Auto AI Enrichment',
        desc: 'laterbox fetches preview covers, summaries, and categorizes media.'
      ),
      (
        step: '03',
        title: 'Enjoy & Organize',
        desc: 'Read, watch inline embeds, add notes, and search anytime.'
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 64 : 24,
        vertical: 60,
      ),
      child: Column(
        children: [
          Text(
            'How laterbox Works',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
              fontSize: isDesktop ? 36 : 26,
            ),
          ),
          const SizedBox(height: 48),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Flex(
              direction: isDesktop ? Axis.horizontal : Axis.vertical,
              children: steps.map((item) {
                final card = Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 8 : 0,
                    vertical: isDesktop ? 0 : 8,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.step,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.desc,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                );
                return isDesktop ? Expanded(child: card) : card;
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection({super.key, required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    final highlights = [
      (
        icon: Icons.shield_outlined,
        title: '100% Offline-First Privacy',
        desc:
            'Your saved articles, links, and personal notes are stored locally on your device in SQLite. No tracking or mandatory cloud dependence.'
      ),
      (
        icon: Icons.devices_rounded,
        title: 'Universal Cross-Platform',
        desc:
            'Works seamlessly across Web, macOS, iOS, Android, Linux, and Windows with background Supabase cloud synchronization.'
      ),
      (
        icon: Icons.bolt_rounded,
        title: 'Instant Performance',
        desc:
            'Zero latency search, instant page loads, and native inline media players for YouTube, Vimeo, and Spotify.'
      ),
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isDesktop ? 64 : 32),
        vertical: isMobile ? 48 : 72,
      ),
      color: theme.colorScheme.surfaceContainerLowest,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  'WHY LATERBOX',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'About laterbox',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: isMobile ? -0.5 : -1,
                  fontSize: isMobile ? 26 : (isDesktop ? 38 : 30),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Built for Focus. Designed for Privacy.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Text(
                  'laterbox was created for readers, researchers, and creators who save valuable information online but get overwhelmed by chaotic browser tabs and lost bookmarks.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                    fontSize: isMobile ? 15 : 17,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              if (isMobile)
                Column(
                  children: highlights
                      .map(
                        (h) => Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  h.icon,
                                  color: theme.colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                h.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                h.desc,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.45,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                )
              else
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: highlights.map((h) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  h.icon,
                                  color: theme.colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                h.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  h.desc,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.45,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadTeaserSection extends StatelessWidget {
  const _DownloadTeaserSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : (isDesktop ? 64 : 32),
        vertical: isMobile ? 36 : 48,
      ),
      color: theme.colorScheme.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Container(
            padding: EdgeInsets.all(isMobile ? 22 : 32),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        color: theme.colorScheme.primary,
                        size: 30,
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
                                'Download laterbox',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  fontSize: isMobile ? 20 : 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Windows v1.0 Ready',
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Standalone Windows installer with offline SQLite and global capture shortcuts (Ctrl+Shift+S). Roadmap bundles for macOS, Linux, iOS & Android coming soon!',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go('/download'),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text('Download Installer & View Roadmap'),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(100),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/extension/connect'),
                      icon: const Icon(Icons.extension_rounded, size: 18),
                      label: const Text('Get Browser Extension'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        side: BorderSide(color: theme.colorScheme.outlineVariant),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CtaBannerSection extends StatelessWidget {
  const _CtaBannerSection({required this.isDesktop});

  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(isDesktop ? 64 : 20),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48 : 24,
        vertical: isDesktop ? 48 : 32,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text(
            'Ready to declutter your bookmarks?',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onPrimary,
              fontSize: isDesktop ? 32 : 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Start saving your favorite links, articles, and notes today.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () => context.go('/inbox'),
            icon: const Icon(Icons.rocket_launch_rounded, size: 20),
            label: const Text('Open laterbox Now'),
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.onPrimary,
              foregroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingFooter extends StatelessWidget {
  const _LandingFooter({
    required this.isDesktop,
    required this.onFeaturesTap,
    required this.onHowItWorksTap,
    required this.onAboutTap,
  });

  final bool isDesktop;
  final VoidCallback onFeaturesTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onAboutTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;

    return Container(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 48,
        isMobile ? 40 : 64,
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
              if (isMobile)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FooterBrandColumn(theme: theme),
                    const SizedBox(height: 32),
                    _FooterLinksColumn(
                      title: 'Product',
                      links: [
                        ('Open App', () => context.go('/inbox')),
                        ('Download App', () => context.go('/download')),
                        ('Sign In', () => context.go('/login')),
                        ('Chrome Extension', () => context.go('/extension/connect')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _FooterLinksColumn(
                      title: 'Explore',
                      links: [
                        ('Features', onFeaturesTap),
                        ('How It Works', onHowItWorksTap),
                        ('About', onAboutTap),
                      ],
                    ),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: _FooterBrandColumn(theme: theme),
                    ),
                    const Spacer(),
                    Expanded(
                      flex: 2,
                      child: _FooterLinksColumn(
                        title: 'Product',
                        links: [
                          ('Open App', () => context.go('/inbox')),
                          ('Download App', () => context.go('/download')),
                          ('Sign In', () => context.go('/login')),
                          ('Chrome Extension', () => context.go('/extension/connect')),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: _FooterLinksColumn(
                        title: 'Explore',
                        links: [
                          ('Features', onFeaturesTap),
                          ('How It Works', onHowItWorksTap),
                          ('About', onAboutTap),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Supported Platforms',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: const [
                              _PlatformChip(label: 'Web', icon: Icons.web_rounded),
                              _PlatformChip(label: 'macOS', icon: Icons.desktop_mac_rounded),
                              _PlatformChip(label: 'iOS', icon: Icons.phone_iphone_rounded),
                              _PlatformChip(label: 'Android', icon: Icons.android_rounded),
                              _PlatformChip(label: 'Linux', icon: Icons.terminal_rounded),
                              _PlatformChip(label: 'Windows', icon: Icons.desktop_windows_rounded),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 48),
              Divider(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 20),
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
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF27C93F),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Offline Storage Active',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
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

class _FooterBrandColumn extends StatelessWidget {
  const _FooterBrandColumn({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                'assets/branding/laterbox-icon.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.bookmark_rounded,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'laterbox',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                fontSize: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Your universal save-for-later memory.\nArticles, videos, links, and personal notes.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _FooterLinksColumn extends StatelessWidget {
  const _FooterLinksColumn({required this.title, required this.links});

  final String title;
  final List<(String, VoidCallback)> links;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        ...links.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: item.$2,
              borderRadius: BorderRadius.circular(4),
              child: Text(
                item.$1,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlatformChip extends StatefulWidget {
  const _PlatformChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  State<_PlatformChip> createState() => _PlatformChipState();
}

class _PlatformChipState extends State<_PlatformChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => context.go('/download'),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _hovered
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.8)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered
                  ? theme.colorScheme.primary.withValues(alpha: 0.5)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 14,
                color: _hovered
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _hovered
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

