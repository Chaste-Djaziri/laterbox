import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/auth_provider.dart';

const _ink = Color(0xFF17211B);
const _muted = Color(0xFF5E6B63);
const _green = Color(0xFF2E6B4F);
const _mint = Color(0xFFE7F2EB);
const _paper = Color(0xFFFAFBF8);
const _line = Color(0xFFDDE4DD);

class LandingScreen extends ConsumerStatefulWidget {
  const LandingScreen({super.key});

  @override
  ConsumerState<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends ConsumerState<LandingScreen> {
  final _scrollController = ScrollController();
  final _featuresKey = GlobalKey();
  final _workflowKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _paper,
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
            child: Column(
              children: [
                _Header(
                  onFeatures: () => _scrollTo(_featuresKey),
                  onWorkflow: () => _scrollTo(_workflowKey),
                ),
                const _Hero(),
                _Features(key: _featuresKey),
                _Workflow(key: _workflowKey),
                const _About(),
                const _FinalCta(),
                const _Footer(),
              ],
            ),
          ),
        ),
      );
  }
}

class _PageWidth extends StatelessWidget {
  const _PageWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      );
}

class _Header extends ConsumerWidget {
  const _Header({required this.onFeatures, required this.onWorkflow});

  final VoidCallback onFeatures;
  final VoidCallback onWorkflow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 760;
    final authenticated =
        ref.watch(authStateProvider).asData?.value.isAuthenticated ?? false;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF7FAFBF8),
        border: Border(bottom: BorderSide(color: _line)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 20 : 40,
        vertical: 16,
      ),
      child: _PageWidth(
        child: Row(
          children: [
            InkWell(
              onTap: () => context.go('/'),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    _BrandMark(),
                    SizedBox(width: 10),
                    Text(
                      'laterbox',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (!compact) ...[
              _NavLink(label: 'Features', onTap: onFeatures),
              _NavLink(label: 'How it works', onTap: onWorkflow),
              _NavLink(
                label: 'Download',
                onTap: () => context.go('/download'),
              ),
              const SizedBox(width: 12),
            ],
            if (!authenticated && !compact)
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in'),
              ),
            const SizedBox(width: 6),
            FilledButton(
              onPressed: () => context.go('/home'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(authenticated ? 'Open inbox' : 'Get started'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: _green,
          borderRadius: BorderRadius.circular(9),
        ),
        child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 20),
      );
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(foregroundColor: _muted),
        child: Text(label),
      );
}

class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 900;

    final copy = Column(
      crossAxisAlignment:
          desktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        const _Eyebrow(icon: Icons.auto_awesome_outlined, text: 'YOUR SPACE TO REMEMBER'),
        const SizedBox(height: 22),
        Text(
          'Save anything now.\nRead, watch & organize later.',
          textAlign: desktop ? TextAlign.left : TextAlign.center,
          style: TextStyle(
            color: _ink,
            fontSize: desktop ? 58 : (width < 500 ? 38 : 48),
            height: 1.04,
            fontWeight: FontWeight.w800,
            letterSpacing: -2.3,
          ),
        ),
        const SizedBox(height: 24),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            'Keep articles, videos, notes, and useful links in one calm place. laterbox adds the context, so everything is easy to find when you need it.',
            textAlign: desktop ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              color: _muted,
              fontSize: 18,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: desktop ? WrapAlignment.start : WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => context.go('/home'),
              style: _primaryButtonStyle(),
              icon: const Icon(Icons.arrow_forward_rounded, size: 19),
              label: const Text('Get Started Free'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(guestModeProvider.notifier).state = true;
                context.go('/home');
              },
              style: _secondaryButtonStyle(),
              icon: const Icon(Icons.play_circle_outline_rounded, size: 19),
              label: const Text('Try Guest Mode'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _TrustPoint(text: 'Free to start'),
            _TrustPoint(text: 'No credit card'),
            _TrustPoint(text: 'Works everywhere'),
          ],
        ),
      ],
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_paper, Color(0xFFF1F6F1)],
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: width < 600 ? 20 : 40,
        vertical: desktop ? 88 : 60,
      ),
      child: _PageWidth(
        child: desktop
            ? Row(
                children: [
                  Expanded(flex: 11, child: copy),
                  const SizedBox(width: 64),
                  const Expanded(flex: 9, child: _ProductPreview()),
                ],
              )
            : Column(
                children: [copy, const SizedBox(height: 52), const _ProductPreview()],
              ),
      ),
    );
  }
}

ButtonStyle _primaryButtonStyle() => FilledButton.styleFrom(
      backgroundColor: _green,
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );

ButtonStyle _secondaryButtonStyle() => OutlinedButton.styleFrom(
      foregroundColor: _ink,
      backgroundColor: Colors.white,
      side: const BorderSide(color: _line),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
    );

class _TrustPoint extends StatelessWidget {
  const _TrustPoint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 16, color: _green),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: _muted, fontSize: 13)),
        ],
      );
}

class _ProductPreview extends StatelessWidget {
  const _ProductPreview();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A254B35),
              blurRadius: 48,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F7F4),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _BrandMark(),
                  const SizedBox(width: 12),
                  const Text('My inbox', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const Spacer(),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                    child: const Icon(Icons.search_rounded, size: 19, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _SavedCard(
                icon: Icons.article_outlined,
                color: Color(0xFFE8EFEA),
                domain: 'designbetter.co',
                title: 'The essential guide to thoughtful product design',
                tag: 'Design',
              ),
              const SizedBox(height: 12),
              const _SavedCard(
                icon: Icons.play_arrow_rounded,
                color: Color(0xFFF0EDE5),
                domain: 'youtube.com',
                title: 'A practical system for learning anything',
                tag: 'Watch later',
              ),
              const SizedBox(height: 12),
              const _SavedCard(
                icon: Icons.lightbulb_outline_rounded,
                color: Color(0xFFE9EDF3),
                domain: 'Personal note',
                title: 'Ideas for the next weekend project',
                tag: 'Ideas',
              ),
            ],
          ),
        ),
      );
}

class _SavedCard extends StatelessWidget {
  const _SavedCard({required this.icon, required this.color, required this.domain, required this.title, required this.tag});

  final IconData icon;
  final Color color;
  final String domain;
  final String title;
  final String tag;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8ECE7)),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(11)),
              child: Icon(icon, color: _green, size: 23),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(domain, style: const TextStyle(color: _muted, fontSize: 11)),
                  const SizedBox(height: 3),
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600, height: 1.25)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(20)),
              child: Text(tag, style: const TextStyle(color: _green, fontSize: 9, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(30)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _green),
            const SizedBox(width: 7),
            Text(text, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
          ],
        ),
      );
}

class _Features extends StatelessWidget {
  const _Features({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: width < 600 ? 20 : 40, vertical: 88),
      child: _PageWidth(
        child: Column(
          children: [
            const _SectionHeading(
              eyebrow: 'ONE HOME FOR EVERYTHING',
              title: 'Everything you need to capture & remember',
              description: 'A focused toolkit that keeps your digital finds useful—not forgotten.',
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (context, constraints) {
                final cards = const [
                  _FeatureCard(icon: Icons.bolt_outlined, title: 'Capture in a click', body: 'Save from the web, your share sheet, or any device without breaking your flow.'),
                  _FeatureCard(icon: Icons.auto_awesome_outlined, title: 'Enriched automatically', body: 'Clean previews, useful metadata, and summaries arrive without extra work.'),
                  _FeatureCard(icon: Icons.search_rounded, title: 'Find it fast', body: 'Search and collections make the right thing easy to rediscover at the right time.'),
                ];
                if (constraints.maxWidth < 760) {
                  return Column(children: [for (var i = 0; i < cards.length; i++) ...[cards[i], if (i < cards.length - 1) const SizedBox(height: 16)]]);
                }
                return const IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.bolt_outlined,
                          title: 'Capture in a click',
                          body:
                              'Save from the web, your share sheet, or any device without breaking your flow.',
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.auto_awesome_outlined,
                          title: 'Enriched automatically',
                          body:
                              'Clean previews, useful metadata, and summaries arrive without extra work.',
                        ),
                      ),
                      SizedBox(width: 18),
                      Expanded(
                        child: _FeatureCard(
                          icon: Icons.search_rounded,
                          title: 'Find it fast',
                          body:
                              'Search and collections make the right thing easy to rediscover at the right time.',
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
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: _paper, border: Border.all(color: _line), borderRadius: BorderRadius.circular(18)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: _mint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: _green, size: 23)),
            const SizedBox(height: 22),
            Text(title, style: const TextStyle(color: _ink, fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.4)),
            const SizedBox(height: 10),
            Text(body, style: const TextStyle(color: _muted, height: 1.55, fontSize: 15)),
          ],
        ),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.eyebrow, required this.title, required this.description});
  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(eyebrow, textAlign: TextAlign.center, style: const TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          const SizedBox(height: 14),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: _ink, fontSize: 36, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -1.2)),
          const SizedBox(height: 14),
          ConstrainedBox(constraints: const BoxConstraints(maxWidth: 610), child: Text(description, textAlign: TextAlign.center, style: const TextStyle(color: _muted, fontSize: 17, height: 1.55))),
        ],
      );
}

class _Workflow extends StatelessWidget {
  const _Workflow({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final narrow = width < 760;
    const steps = [
      _Step(number: '01', title: 'Save it', body: 'Send any link, thought, or file to laterbox.'),
      _Step(number: '02', title: 'We tidy it', body: 'The details and preview are organized for you.'),
      _Step(number: '03', title: 'Come back anytime', body: 'Search, browse, and pick up exactly where you left off.'),
    ];
    return Container(
      color: _ink,
      padding: EdgeInsets.symmetric(horizontal: width < 600 ? 20 : 40, vertical: 88),
      child: _PageWidth(
        child: Column(
          children: [
            const Text('A SIMPLE FLOW', style: TextStyle(color: Color(0xFF9FC9B0), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
            const SizedBox(height: 14),
            const Text('How laterbox Works', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.1)),
            const SizedBox(height: 46),
            if (narrow)
              const Column(children: [_Step(number: '01', title: 'Save it', body: 'Send any link, thought, or file to laterbox.'), SizedBox(height: 28), _Step(number: '02', title: 'We tidy it', body: 'The details and preview are organized for you.'), SizedBox(height: 28), _Step(number: '03', title: 'Come back anytime', body: 'Search, browse, and pick up exactly where you left off.')])
            else
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (var i = 0; i < steps.length; i++) ...[Expanded(child: steps[i]), if (i < steps.length - 1) const Padding(padding: EdgeInsets.only(top: 24), child: Icon(Icons.arrow_forward_rounded, color: Color(0xFF53635A)))]]),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.title, required this.body});
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFF25362D), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF3E5749))), child: Text(number, style: const TextStyle(color: Color(0xFFA9D2B9), fontWeight: FontWeight.w800))),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 9),
          Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFB8C1BB), fontSize: 14, height: 1.5)),
        ],
      );
}

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: const Color(0xFFF2F6F1),
      padding: EdgeInsets.symmetric(horizontal: width < 600 ? 20 : 40, vertical: 76),
      child: const _PageWidth(
        child: Column(
          children: [
            Icon(Icons.format_quote_rounded, color: _green, size: 35),
            SizedBox(height: 16),
            Text('About laterbox', style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
            SizedBox(height: 18),
            SizedBox(width: 760, child: Text('The internet is full of things worth keeping. laterbox gives them a quiet, dependable home—without turning organization into another job.', textAlign: TextAlign.center, style: TextStyle(color: _ink, fontSize: 27, height: 1.4, fontWeight: FontWeight.w600, letterSpacing: -0.6))),
          ],
        ),
      ),
    );
  }
}

class _FinalCta extends StatelessWidget {
  const _FinalCta();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: width < 600 ? 20 : 40, vertical: 88),
      child: _PageWidth(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: width < 600 ? 24 : 64, vertical: 58),
          decoration: BoxDecoration(color: _green, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              const Text('Make space for what matters.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 36, height: 1.15, fontWeight: FontWeight.w800, letterSpacing: -1.1)),
              const SizedBox(height: 14),
              const Text('Start saving in seconds. Your future self will thank you.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFFD5E9DC), fontSize: 17)),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: _green, padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.arrow_forward_rounded, size: 19),
                label: const Text('Create your laterbox', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(width < 600 ? 20 : 40, 0, width < 600 ? 20 : 40, 32),
      child: const _PageWidth(
        child: Column(
          children: [
            Divider(color: _line),
            SizedBox(height: 24),
            Row(
              children: [
                _BrandMark(),
                SizedBox(width: 10),
                Text('laterbox', style: TextStyle(color: _ink, fontWeight: FontWeight.w800, fontSize: 18)),
                Spacer(),
                Flexible(child: Text('Save now. Enjoy later.', textAlign: TextAlign.right, style: TextStyle(color: _muted, fontSize: 13))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
