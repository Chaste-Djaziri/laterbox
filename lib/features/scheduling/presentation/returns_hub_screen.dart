import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Mobile landing page for every schedule state. Keeping this separate from a
/// single schedule makes the Returns tab a useful navigation destination.
class ReturnsHubScreen extends StatelessWidget {
  const ReturnsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = const [
      _ReturnDestination(
        title: 'Today',
        subtitle: 'Items ready for your attention now',
        icon: Icons.today_rounded,
        path: '/today',
      ),
      _ReturnDestination(
        title: 'Upcoming',
        subtitle: 'See what LaterBox will bring back next',
        icon: Icons.event_available_rounded,
        path: '/upcoming',
      ),
      _ReturnDestination(
        title: 'Someday',
        subtitle: 'Keep ideas with no deadline',
        icon: Icons.all_inclusive_rounded,
        path: '/someday',
      ),
      _ReturnDestination(
        title: 'Inbox',
        subtitle: 'Review items that have already returned',
        icon: Icons.inbox_rounded,
        path: '/inbox',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Returns',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          Text(
            'When should LaterBox bring things back?',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          for (final card in cards) ...[
            _ReturnDestinationCard(destination: card),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ReturnDestination {
  const _ReturnDestination({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.path,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String path;
}

class _ReturnDestinationCard extends StatelessWidget {
  const _ReturnDestinationCard({required this.destination});

  final _ReturnDestination destination;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
      ),
      child: InkWell(
        onTap: () => context.go(destination.path),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6EDB0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(destination.icon, color: const Color(0xFF171711)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      destination.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}
