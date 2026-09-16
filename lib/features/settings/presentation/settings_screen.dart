import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/billing/billing_providers.dart';
import '../../../core/billing/entitlement.dart';
import '../../../core/billing/entitlement_presentation.dart';
import '../../../core/database/database_providers.dart';
import '../../../core/desktop/desktop_actions.dart';
import '../../../core/desktop/desktop_providers.dart';
import '../../../core/desktop/updater_service.dart';
import '../../../core/ios/ios_app_store_update_service.dart';
import '../../../core/settings/desktop_settings.dart';
import '../../../core/settings/desktop_shortcut.dart';
import '../../../core/settings/settings_providers.dart';
import '../../../core/sync/sync_providers.dart';
import '../../../shared/widgets/cloud_sync_indicator.dart';
import '../../collections/presentation/collection_providers.dart';
import '../../inbox/presentation/inbox_providers.dart';
import '../../library/presentation/library_providers.dart';
import '../../../core/app_icon/app_icon_providers.dart';
import '../../../core/app_icon/app_icon_service.dart';
import 'app_icon_screen.dart';

const _accessibilitySettingsUrl =
    'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility';
const _privacyPolicyUrl = 'https://laterbox.dev/privacy';
const _termsOfServiceUrl = 'https://laterbox.dev/terms';

/// Settings and Account Management screen for Mobile & Desktop.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = !kIsWeb
        ? (defaultTargetPlatform == TargetPlatform.macOS ||
              defaultTargetPlatform == TargetPlatform.linux ||
              defaultTargetPlatform == TargetPlatform.windows ||
              width >= 700)
        : width >= 900;

    final auth = ref.watch(authStateProvider).asData?.value;
    final isGuest =
        ref.watch(guestModeProvider) || !(auth?.isAuthenticated ?? false);
    final email = auth?.email;
    final userId = auth?.userId;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.6),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inbox');
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 20,
            vertical: 16,
          ),
          children: [
            _SectionHeader('Plan'),
            const _ProSubscriptionCard(),
            const SizedBox(height: 12),
            // 1. Account Section
            _SectionHeader('Account & Security'),
            if (!isGuest && email != null)
              _AuthenticatedAccountCard(email: email, userId: userId ?? '')
            else
              const _GuestAccountCard(),

            // 2. Desktop Controls (macOS / Windows / Linux)
            if (isDesktop) ...[
              const SizedBox(height: 12),
              _SectionHeader('Quick Capture'),
              const _DesktopShortcutSettings(),
            ],

            // 3. App Icon (iOS only)
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
              const SizedBox(height: 12),
              _SectionHeader('App Icon'),
              const _AppIconSettingsTile(),
            ],

            // 4. Cloud Sync & Storage Diagnostics
            const SizedBox(height: 12),
            _SectionHeader('Cloud Sync & Diagnostics'),
            const _SyncAndStorageCard(),

            // 4. About & Legal
            const SizedBox(height: 12),
            _SectionHeader('About & Legal'),
            const _AboutAndLegalCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ProSubscriptionCard extends ConsumerWidget {
  const _ProSubscriptionCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlement =
        ref.watch(entitlementProvider).valueOrNull ?? const Entitlement.free();
    final presentation = EntitlementPresentation.from(entitlement);
    final isPro = entitlement.hasProAccess;
    final theme = Theme.of(context);
    final isStoreBuild =
        laterBoxDistribution == 'play' || laterBoxDistribution == 'app-store';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD7FF27)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presentation.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  !isPro && isStoreBuild
                      ? 'Local saving stays free. Existing Pro subscribers can sign in to unlock connected features.'
                      : presentation.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white70,
                  ),
                ),
                if (entitlement.billingWarning != null) ...[
                  const SizedBox(height: 5),
                  const Text(
                    'Payment needs attention. Manage billing on laterbox.dev.',
                    style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                  ),
                ],
                if (presentation.progress != null) ...[
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: presentation.progress,
                    minHeight: 5,
                    borderRadius: BorderRadius.circular(99),
                    color: presentation.severity == EntitlementSeverity.warning
                        ? Colors.amberAccent
                        : const Color(0xFFD7FF27),
                    backgroundColor: Colors.white12,
                  ),
                ],
              ],
            ),
          ),
          if (canOpenWebCheckout || isStoreBuild)
            FilledButton(
              onPressed: () async {
                if (isAppleAppStoreBuild &&
                    isPro &&
                    entitlement.provider == 'apple') {
                  await ref.read(applePurchaseServiceProvider).openManagement();
                } else if (isStoreBuild) {
                  if (context.mounted) context.push('/plans');
                } else {
                  if (context.mounted) context.push('/plans');
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD7FF27),
                foregroundColor: Colors.black,
              ),
              child: Text(presentation.actionLabel),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account Cards & Dialogs
// ---------------------------------------------------------------------------

class _AuthenticatedAccountCard extends ConsumerWidget {
  const _AuthenticatedAccountCard({required this.email, required this.userId});

  final String email;
  final String userId;

  void _openChangePassword(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _ChangePasswordDialog(),
    );
  }

  void _openDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            email,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Tooltip(
                          message: 'Email cannot be changed',
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Locked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (userId.isNotEmpty)
                      Text(
                        'User ID: $userId',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'Menlo',
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openChangePassword(context),
                icon: const Icon(Icons.key_rounded, size: 16),
                label: const Text('Change Password'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authRepositoryProvider).signOut();
                  ref.read(guestModeProvider.notifier).state = true;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signed out successfully')),
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, size: 16),
                label: const Text('Sign Out'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Danger zone
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Colors.red.shade900,
                        ),
                      ),
                      Text(
                        'Permanently wipe your account, saved links, notes, and cloud data.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.red.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _openDeleteAccount(context),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestAccountCard extends ConsumerWidget {
  const _GuestAccountCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 28,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Guest Mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You are currently saving items locally on this device. Sign in or create an account to sync seamlessly across mobile, desktop, and web.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () {
              ref.read(guestModeProvider.notifier).state = false;
              context.go('/login');
            },
            icon: const Icon(Icons.login_rounded, size: 16),
            label: const Text('Sign In or Create Account'),
          ),
        ],
      ),
    );
  }
}

/// Change Password Dialog
class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .updatePassword(_passwordController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  hintText: 'Min. 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscure,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  hintText: 'Repeat new password',
                ),
                validator: (val) {
                  if (val != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update Password'),
        ),
      ],
    );
  }
}

/// Delete Account Dialog
class _DeleteAccountDialog extends ConsumerStatefulWidget {
  const _DeleteAccountDialog();

  @override
  ConsumerState<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<_DeleteAccountDialog> {
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_confirmController.text.trim() != 'DELETE') return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .deleteAccount(
            onClearLocalData: () async {
              await ref.read(appDatabaseProvider).clearAllData();
            },
          );
      ref.read(guestModeProvider.notifier).state = true;
      if (!mounted) return;
      Navigator.of(context).pop();
      context.go('/login');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your account and all associated data have been permanently deleted.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red),
          SizedBox(width: 8),
          Text('Delete Account?'),
        ],
      ),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This action is irreversible. All your saved links, notes, collections, attachments, and cloud sync data will be permanently destroyed.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'To confirm, type DELETE below:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'DELETE',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
          ),
          onPressed: _confirmController.text.trim() == 'DELETE' && !_loading
              ? _submit
              : null,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Permanently Delete'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cloud Sync & Diagnostics
// ---------------------------------------------------------------------------

class _SyncAndStorageCard extends ConsumerWidget {
  const _SyncAndStorageCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final allItems = ref.watch(allItemsProvider);
    final keptItems = ref.watch(keptProvider);
    final collections = ref.watch(collectionCountsProvider);
    final isPro = ref.watch(hasProAccessProvider);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sync Status',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const CloudSyncIndicator(compact: false),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Total Items',
                  value: '${allItems.value?.length ?? 0}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Kept',
                  value: '${keptItems.value?.length ?? 0}',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: 'Collections',
                  value: '${collections.value?.length ?? 0}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.tonalIcon(
            onPressed: () async {
              if (!isPro) {
                await showSyncPlansSheet(context);
                return;
              }
              await ref.read(syncCoordinatorProvider).syncNow();
              ref.invalidate(inboxItemsProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Cloud sync completed')),
                );
              }
            },
            icon: Icon(
              isPro ? Icons.sync_rounded : Icons.workspace_premium_outlined,
              size: 16,
            ),
            label: const Text('Force Sync Now'),
          ),
        ],
      ),
    );
  }
}

class _AppIconSettingsTile extends ConsumerWidget {
  const _AppIconSettingsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final currentIconAsync = ref.watch(currentAppIconProvider);
    final activeId = currentIconAsync.valueOrNull;
    final currentOption = AppIconOption.fromId(activeId);

    return Material(
      color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              currentOption.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: colors.surfaceContainerHighest,
                child: Icon(Icons.apps_rounded, color: colors.onSurfaceVariant),
              ),
            ),
          ),
        ),
        title: Text(
          'App Icon',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${currentOption.name} • ${currentOption.subtitle}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentOption.name,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
          ],
        ),
        onTap: () {
          final router = GoRouter.maybeOf(context);
          if (router != null) {
            context.push('/settings/icon');
          } else {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AppIconScreen()));
          }
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop Shortcuts & Behaviors
// ---------------------------------------------------------------------------

class _DesktopShortcutSettings extends ConsumerWidget {
  const _DesktopShortcutSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings =
        ref.watch(desktopSettingsProvider).value ?? DesktopSettings.defaults();
    final actions = ref.watch(desktopActionsProvider);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            _ShortcutTile(shortcut: settings.quickCaptureShortcut),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Use selected text when available'),
              subtitle: const Text('Falls back to the clipboard otherwise'),
              secondary: const Icon(Icons.text_fields_rounded),
              value: settings.useSelectedText,
              onChanged: (value) =>
                  unawaited(actions.setUseSelectedText(value)),
            ),
            const _AccessibilityTile(),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Close Quick Capture when focus is lost'),
              subtitle: const Text('Only while capture is active'),
              secondary: const Icon(Icons.center_focus_weak_rounded),
              value: settings.closeOnFocusLoss,
              onChanged: (value) =>
                  unawaited(actions.setCloseOnFocusLoss(value)),
            ),
            SwitchListTile(
              title: const Text('Keep LaterBox running when window closes'),
              subtitle: const Text('Stays in the menu bar instead of quitting'),
              secondary: const Icon(Icons.power_settings_new_rounded),
              value: settings.keepRunningOnWindowClose,
              onChanged: (value) =>
                  unawaited(actions.setKeepRunningOnWindowClose(value)),
            ),
            SwitchListTile(
              title: const Text('Launch LaterBox at login'),
              subtitle: const Text('Starts quietly in the menu bar'),
              secondary: const Icon(Icons.login_rounded),
              value: settings.launchAtLogin,
              onChanged: (value) async {
                if (value) {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Launch at login?'),
                      content: const Text(
                        'LaterBox will start quietly in the menu bar after you log in — no window, no interruption. '
                        'Capture anything without breaking focus from the notch or ⌥Space. '
                        'You can disable this anytime in Settings → Quick Capture.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Enable'),
                        ),
                      ],
                    ),
                  );
                  if (ok != true) return;
                }
                unawaited(actions.setLaunchAtLogin(value));
              },
            ),
            SwitchListTile(
              title: const Text('Show LaterBox in menu bar'),
              secondary: const Icon(Icons.menu_rounded),
              value: settings.showInMenuBar,
              onChanged: (value) => unawaited(actions.setShowInMenuBar(value)),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Live in Top Screen Notch (macOS)'),
              subtitle: const Text(
                'Floats at top-center screen with live Dynamic Island',
              ),
              secondary: const Icon(Icons.laptop_mac_rounded),
              value: settings.enableNotchMode,
              onChanged: (value) =>
                  unawaited(actions.setEnableNotchMode(value)),
            ),
            SwitchListTile(
              title: const Text('Watch active screen & browser tabs'),
              subtitle: const Text(
                'Detects active links, references, and frontmost apps',
              ),
              secondary: const Icon(Icons.visibility_rounded),
              value: settings.watchActiveScreen,
              onChanged: (value) async {
                if (value) {
                  final proceed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Enable Watch Mode?'),
                      content: const Text(
                        'Watch Mode uses on-device Vision OCR (ScreenCaptureKit) to detect links and quotes on your screen. '
                        'Screen content never leaves your Mac — it is not persisted or uploaded until you tap Save. '
                        'You’ll be asked for Screen Recording permission next; grant it in System Settings → Privacy & Security → Screen Recording for the notch to see the screen.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  );
                  if (proceed != true) return;
                  // Trigger system prompt; if still denied we still persist the preference
                  // but surface guidance — the native watcher will surface a permission error.
                  try {
                    final trusted = await ref
                        .read(desktopActionsProvider)
                        .ensureWatchModePermission();
                    if (!trusted && context.mounted) {
                      final open = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Screen Recording required'),
                          content: const Text(
                            'LaterBox needs Screen Recording permission to watch the screen. '
                            'Open System Settings → Privacy & Security → Screen Recording and enable LaterBox, then return and try again.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Later'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Open Settings'),
                            ),
                          ],
                        ),
                      );
                      if (open == true) {
                        await ref
                            .read(desktopActionsProvider)
                            .openScreenRecordingSettings();
                      }
                    }
                  } catch (_) {}
                }
                unawaited(actions.setWatchActiveScreen(value));
              },
            ),
            const _ScreenRecordingTile(),
            SwitchListTile(
              title: const Text('Capture word references with highlight URLs'),
              subtitle: const Text(
                'Generates W3C #:~:text= scroll-to-text links',
              ),
              secondary: const Icon(Icons.format_quote_rounded),
              value: settings.autoCopyWordReferences,
              onChanged: (value) =>
                  unawaited(actions.setAutoCopyWordReferences(value)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  const _ShortcutTile({required this.shortcut});

  final DesktopShortcut shortcut;

  Future<void> _pick(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ShortcutDialog(current: shortcut),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: const Icon(Icons.keyboard_rounded),
      title: const Text('Shortcut'),
      subtitle: Text(
        shortcut.displayLabel,
        style: theme.textTheme.titleMedium?.copyWith(
          fontFamily: 'Menlo',
          fontWeight: FontWeight.w700,
        ),
      ),
      trailing: FilledButton.tonal(
        onPressed: () => _pick(context),
        child: const Text('Change shortcut'),
      ),
    );
  }
}

class _ShortcutDialog extends ConsumerStatefulWidget {
  const _ShortcutDialog({required this.current});

  final DesktopShortcut current;

  @override
  ConsumerState<_ShortcutDialog> createState() => _ShortcutDialogState();
}

class _ShortcutDialogState extends ConsumerState<_ShortcutDialog> {
  final _focusNode = FocusNode();
  DesktopShortcut? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final preview = _preview;
    if (preview == null) return;
    final ok = await ref
        .read(desktopActionsProvider)
        .changeQuickCaptureShortcut(preview);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _error =
            "This shortcut couldn't be registered. It may already be used by "
            'another application.';
      });
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.physicalKey == PhysicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return;
    }
    if (_isModifier(event.physicalKey)) return;

    final modifiers = _pressedModifiers();
    if (modifiers.isEmpty) {
      setState(() {
        _error = 'Add a modifier like ⌥ or ⌘ for a safe global shortcut.';
      });
      return;
    }
    setState(() {
      _error = null;
      _preview = DesktopShortcut(
        keyId: event.physicalKey.usbHidUsage,
        modifiers: modifiers,
      );
    });
  }

  bool _isModifier(PhysicalKeyboardKey key) {
    return key == PhysicalKeyboardKey.altLeft ||
        key == PhysicalKeyboardKey.altRight ||
        key == PhysicalKeyboardKey.controlLeft ||
        key == PhysicalKeyboardKey.controlRight ||
        key == PhysicalKeyboardKey.shiftLeft ||
        key == PhysicalKeyboardKey.shiftRight ||
        key == PhysicalKeyboardKey.metaLeft ||
        key == PhysicalKeyboardKey.metaRight;
  }

  List<DesktopModifier> _pressedModifiers() {
    final physical = HardwareKeyboard.instance.physicalKeysPressed;
    final modifiers = <DesktopModifier>[];
    if (physical.contains(PhysicalKeyboardKey.altLeft) ||
        physical.contains(PhysicalKeyboardKey.altRight)) {
      modifiers.add(DesktopModifier.alt);
    }
    if (physical.contains(PhysicalKeyboardKey.controlLeft) ||
        physical.contains(PhysicalKeyboardKey.controlRight)) {
      modifiers.add(DesktopModifier.control);
    }
    if (physical.contains(PhysicalKeyboardKey.shiftLeft) ||
        physical.contains(PhysicalKeyboardKey.shiftRight)) {
      modifiers.add(DesktopModifier.shift);
    }
    if (physical.contains(PhysicalKeyboardKey.metaLeft) ||
        physical.contains(PhysicalKeyboardKey.metaRight)) {
      modifiers.add(DesktopModifier.meta);
    }
    return modifiers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final preview = _preview;
    return AlertDialog(
      title: const Text('Change Quick Capture shortcut'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Press the new key combination.'),
            const SizedBox(height: 16),
            Container(
              height: 56,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: theme.colorScheme.outline),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                preview?.displayLabel ?? 'Press a combination',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontFamily: 'Menlo',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Focus(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (_, event) {
                _handleKey(event);
                return KeyEventResult.handled;
              },
              child: const SizedBox(height: 24, width: double.infinity),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: preview == null ? null : _save,
          child: const Text('Save shortcut'),
        ),
      ],
    );
  }
}

class _AccessibilityTile extends ConsumerWidget {
  const _AccessibilityTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trusted = ref.watch(accessibilityTrustedProvider);

    return ListTile(
      leading: const Icon(Icons.accessibility_new_rounded),
      title: const Text('Selected text capture'),
      subtitle: Text(
        trusted.when(
          data: (granted) => granted
              ? 'Accessibility access enabled'
              : 'Accessibility access required',
          loading: () => 'Checking permission…',
          error: (_, _) => 'Accessibility access required',
        ),
      ),
      trailing: trusted.when(
        data: (granted) => granted
            ? Icon(Icons.check_circle_rounded, color: Colors.green.shade600)
            : FilledButton.tonal(
                onPressed: () =>
                    unawaited(launchUrl(Uri.parse(_accessibilitySettingsUrl))),
                child: const Text('Open System Settings'),
              ),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => FilledButton.tonal(
          onPressed: () =>
              unawaited(launchUrl(Uri.parse(_accessibilitySettingsUrl))),
          child: const Text('Open System Settings'),
        ),
      ),
    );
  }
}

class _ScreenRecordingTile extends ConsumerWidget {
  const _ScreenRecordingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only show on macOS; on other platforms render nothing.
    if (defaultTargetPlatform != TargetPlatform.macOS) {
      return const SizedBox.shrink();
    }
    // We query trust lazily via MacOSCompanion; show a static tile that checks on tap.
    return ListTile(
      leading: const Icon(Icons.screen_search_desktop_rounded),
      title: const Text('Screen Recording for Watch Mode'),
      subtitle: const Text(
        'Required for notch Watch Mode — on-device only, never uploaded',
      ),
      trailing: FilledButton.tonal(
        onPressed: () async {
          final trusted = await ref
              .read(desktopActionsProvider)
              .ensureWatchModePermission();
          if (!trusted && context.mounted) {
            unawaited(
              launchUrl(
                Uri.parse(
                  'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture',
                ),
              ),
            );
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Screen Recording permission granted'),
              ),
            );
            ref.invalidate(accessibilityTrustedProvider);
          }
        },
        child: const Text('Check Permission'),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// About & Legal
// ---------------------------------------------------------------------------

class _AboutAndLegalCard extends ConsumerStatefulWidget {
  const _AboutAndLegalCard();

  @override
  ConsumerState<_AboutAndLegalCard> createState() => _AboutAndLegalCardState();
}

class _AboutAndLegalCardState extends ConsumerState<_AboutAndLegalCard> {
  String _versionText = 'Version …';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionText =
            'Version ${info.version} (Build ${info.buildNumber}) • ${_platformLabel()}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionText = 'Version unknown • ${_platformLabel()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Image.asset(
                'assets/branding/laterbox-icon.png',
                width: 28,
                height: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LaterBox',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      _versionText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (defaultTargetPlatform == TargetPlatform.macOS ||
              (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS)) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: defaultTargetPlatform == TargetPlatform.macOS
                  ? _UpdateButton()
                  : const _IosAppStoreUpdateButton(),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined, size: 20),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => unawaited(
                launchUrl(
                  Uri.parse(_privacyPolicyUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.description_outlined, size: 20),
              title: const Text('Terms of Service'),
              trailing: const Icon(Icons.open_in_new_rounded, size: 16),
              onTap: () => unawaited(
                launchUrl(
                  Uri.parse(_termsOfServiceUrl),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _platformLabel() {
    if (kIsWeb) return 'Web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.macOS:
        return 'macOS • Sparkle';
      case TargetPlatform.windows:
        return 'Windows';
      case TargetPlatform.linux:
        return 'Linux';
      case TargetPlatform.iOS:
        return 'iOS';
      case TargetPlatform.android:
        return 'Android';
      default:
        return defaultTargetPlatform.name;
    }
  }
}

class _UpdateButton extends ConsumerWidget {
  const _UpdateButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.system_update_rounded, size: 16),
      label: const Text('Check for Updates'),
      onPressed: () async {
        const svc = UpdaterService();
        final ok = await svc.checkForUpdates();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                ok ? 'Checking for updates…' : 'Updater not available — add Sparkle via Xcode SPM to enable',
              ),
            ),
          );
        }
      },
    );
  }
}

class _IosAppStoreUpdateButton extends ConsumerWidget {
  const _IosAppStoreUpdateButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.tonalIcon(
      icon: const Icon(Icons.system_update_rounded, size: 16),
      label: const Text('Check for Updates'),
      onPressed: () async {
        final notifier = ref.read(iosAppStoreUpdateProvider.notifier);
        await notifier.checkForUpdate(force: true);
        if (!context.mounted) return;
        final update = ref.read(iosAppStoreUpdateProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              update.shouldShow
                  ? 'Update ${update.latestVersion} is available on the App Store.'
                  : 'LaterBox is up to date.',
            ),
          ),
        );
      },
    );
  }
}
