import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.platformOverride});

  final TargetPlatform? platformOverride;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  TargetPlatform get _platform =>
      widget.platformOverride ?? defaultTargetPlatform;

  _DeviceTutorial get _tutorial => _DeviceTutorial.forPlatform(_platform);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _closeTutorial() {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/inbox');
    }
  }

  void _selectStep(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tutorial = _tutorial;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'LaterBox guide',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _closeTutorial,
          tooltip: 'Back to Inbox',
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    isWide ? 32 : 20,
                    16,
                    isWide ? 32 : 20,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(theme, tutorial, isWide),
                      const SizedBox(height: 16),
                      Expanded(
                        child: isWide
                            ? _buildDesktopLayout(theme, tutorial)
                            : _buildCompactLayout(theme, tutorial),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, _DeviceTutorial tutorial, bool isWide) {
    return Container(
      padding: EdgeInsets.all(isWide ? 24 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              tutorial.deviceIcon,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tutorial.eyebrow,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tutorial.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tutorial.intro,
                  maxLines: isWide ? 2 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onInverseSurface.withValues(
                      alpha: 0.72,
                    ),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(ThemeData theme, _DeviceTutorial tutorial) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 290, child: _buildStepNavigation(theme, tutorial)),
        const SizedBox(width: 16),
        Expanded(child: _buildPageView(theme, tutorial, compact: false)),
      ],
    );
  }

  Widget _buildCompactLayout(ThemeData theme, _DeviceTutorial tutorial) {
    return Column(
      children: [
        _buildProgress(theme, tutorial.steps.length),
        const SizedBox(height: 12),
        Expanded(child: _buildPageView(theme, tutorial, compact: true)),
        const SizedBox(height: 12),
        _buildNavigationButtons(theme, tutorial.steps.length),
      ],
    );
  }

  Widget _buildStepNavigation(ThemeData theme, _DeviceTutorial tutorial) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Text(
              'YOUR QUICK START',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
          ...List.generate(tutorial.steps.length, (index) {
            final step = tutorial.steps[index];
            final selected = index == _currentPage;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Material(
                color: selected
                    ? theme.colorScheme.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: () => _selectStep(index),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          child: Text(
                            '${index + 1}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            step.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: _buildNavigationButtons(theme, tutorial.steps.length),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(ThemeData theme, int stepCount) {
    return Row(
      children: [
        Text(
          'Step ${_currentPage + 1} of $stepCount',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / stepCount,
            minHeight: 6,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildPageView(
    ThemeData theme,
    _DeviceTutorial tutorial, {
    required bool compact,
  }) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) => setState(() => _currentPage = index),
      itemCount: tutorial.steps.length,
      itemBuilder: (context, index) => _buildStepCard(
        theme,
        tutorial.steps[index],
        index,
        tutorial.steps.length,
        compact,
      ),
    );
  }

  Widget _buildStepCard(
    ThemeData theme,
    _TutorialStep step,
    int index,
    int stepCount,
    bool compact,
  ) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(compact ? 20 : 28),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    step.icon,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP ${index + 1} OF $stepCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        step.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              step.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (step.shortcut case final shortcut?) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step.shortcutLabel ?? 'SHORTCUT',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.65,
                        ),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shortcut,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.primaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 22),
            const Divider(),
            const SizedBox(height: 14),
            ...step.details.map(
              (detail) => Padding(
                padding: const EdgeInsets.only(bottom: 13),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 19,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        detail,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (step.note case final note?) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 19,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(ThemeData theme, int stepCount) {
    final isLast = _currentPage == stepCount - 1;
    return Row(
      children: [
        if (_currentPage > 0) ...[
          Expanded(
            child: OutlinedButton(
              onPressed: () => _selectStep(_currentPage - 1),
              child: const Text('Previous'),
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          flex: _currentPage > 0 ? 1 : 2,
          child: FilledButton.icon(
            onPressed: isLast
                ? _closeTutorial
                : () => _selectStep(_currentPage + 1),
            icon: Icon(
              isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
            ),
            label: Text(isLast ? 'Go to Inbox' : 'Next step'),
          ),
        ),
      ],
    );
  }
}

class _DeviceTutorial {
  const _DeviceTutorial({
    required this.eyebrow,
    required this.title,
    required this.intro,
    required this.deviceIcon,
    required this.steps,
  });

  final String eyebrow;
  final String title;
  final String intro;
  final IconData deviceIcon;
  final List<_TutorialStep> steps;

  factory _DeviceTutorial.forPlatform(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.macOS => _macOS,
      TargetPlatform.windows => _windows,
      TargetPlatform.linux => _linux,
      TargetPlatform.iOS => _iOS,
      TargetPlatform.android => _android,
      TargetPlatform.fuchsia => _android,
    };
  }

  static const _macOS = _DeviceTutorial(
    eyebrow: 'MACOS QUICK START',
    title: 'Set up LaterBox on your Mac',
    intro: 'Capture from any Mac app, save from Safari, and keep your library ready offline.',
    deviceIcon: Icons.laptop_mac_rounded,
    steps: [
      _TutorialStep(
        icon: Icons.keyboard_command_key_rounded,
        title: 'Capture without changing apps',
        description: 'Press Option and Space from any app to open the floating Quick Capture window.',
        shortcutLabel: 'GLOBAL SHORTCUT',
        shortcut: '⌥ Space',
        details: [
          'Paste a URL or write a note',
          'Press Return to save it to Inbox',
          'Change the shortcut from Settings at any time',
        ],
        note: 'LaterBox can stay in the menu bar, so capture remains available when the main window is closed.',
      ),
      _browserStep,
      _organizeStep,
      _syncStep,
    ],
  );

  static const _windows = _DeviceTutorial(
    eyebrow: 'WINDOWS QUICK START',
    title: 'Set up LaterBox on Windows',
    intro: 'Capture from any Windows program, use the system tray, and keep reading when you are offline.',
    deviceIcon: Icons.desktop_windows_rounded,
    steps: [
      _TutorialStep(
        icon: Icons.keyboard_alt_rounded,
        title: 'Capture without changing programs',
        description: 'Press Ctrl, Alt, and Space together to open Quick Capture above your current program.',
        shortcutLabel: 'GLOBAL SHORTCUT',
        shortcut: 'Ctrl + Alt + Space',
        details: [
          'Paste a link or type a thought',
          'Press Enter to save it immediately',
          'Open quick actions from the system tray',
        ],
        note: 'If another program uses this shortcut, choose a replacement in LaterBox Settings.',
      ),
      _browserStep,
      _organizeStep,
      _syncStep,
    ],
  );

  static const _linux = _DeviceTutorial(
    eyebrow: 'LINUX QUICK START',
    title: 'Set up LaterBox on Linux',
    intro: 'Capture from your desktop, save from Chromium or Firefox, and organize everything in one inbox.',
    deviceIcon: Icons.computer_rounded,
    steps: [
      _TutorialStep(
        icon: Icons.keyboard_alt_rounded,
        title: 'Open Quick Capture',
        description: 'Press Alt and Space together from another app, then enter a URL or note.',
        shortcutLabel: 'GLOBAL SHORTCUT',
        shortcut: 'Alt + Space',
        details: [
          'Press Enter to save',
          'Keep LaterBox running in the background',
          'Choose another shortcut in Settings if needed',
        ],
        note: 'Some Linux desktop environments already use Alt + Space. LaterBox lets you replace it safely.',
      ),
      _browserStep,
      _organizeStep,
      _syncStep,
    ],
  );

  static const _iOS = _DeviceTutorial(
    eyebrow: 'IPHONE AND IPAD QUICK START',
    title: 'Save from your iPhone or iPad',
    intro: 'Send links, videos, text, and files to LaterBox from the Apple share sheet.',
    deviceIcon: Icons.phone_iphone_rounded,
    steps: [
      _TutorialStep(
        icon: Icons.ios_share_rounded,
        title: 'Save with the Share button',
        description: 'In Safari, YouTube, or another app, tap Share and choose LaterBox.',
        shortcutLabel: 'MAIN ACTION',
        shortcut: 'Share → LaterBox',
        details: [
          'Open the page or item you want to keep',
          'Tap the square Share button',
          'Choose LaterBox and confirm the save',
        ],
        note: 'If LaterBox is hidden, tap More in the app row, then add LaterBox to Favorites.',
      ),
      _mobileFilesStep,
      _organizeStep,
      _syncStep,
    ],
  );

  static const _android = _DeviceTutorial(
    eyebrow: 'ANDROID QUICK START',
    title: 'Save from your Android device',
    intro: 'Send links, videos, text, and files to LaterBox from the Android share sheet.',
    deviceIcon: Icons.android_rounded,
    steps: [
      _TutorialStep(
        icon: Icons.share_rounded,
        title: 'Share directly to LaterBox',
        description: 'In Chrome, YouTube, Reddit, or another app, tap Share and select LaterBox.',
        shortcutLabel: 'MAIN ACTION',
        shortcut: 'Share → LaterBox',
        details: [
          'Open the item you want to keep',
          'Tap Share from the app menu',
          'Select LaterBox to save it to Inbox',
        ],
        note: 'On supported phones, long press LaterBox in the share sheet to pin it near the top.',
      ),
      _mobileFilesStep,
      _organizeStep,
      _syncStep,
    ],
  );

  static const _browserStep = _TutorialStep(
    icon: Icons.extension_rounded,
    title: 'Add the browser extension',
    description: 'Use the LaterBox browser button to save the current page without leaving it.',
    details: [
      'Install the extension for your browser',
      'Open it and choose Connect to LaterBox',
      'Select the toolbar button on any page to save',
    ],
    note: 'Your extension uses the same account as the desktop app, so new saves appear in the same Inbox.',
  );

  static const _mobileFilesStep = _TutorialStep(
    icon: Icons.attach_file_rounded,
    title: 'Save text and files too',
    description: 'LaterBox can receive selected text, images, documents, and several shared files at once.',
    details: [
      'Select text before opening Share to preserve it',
      'Share several files as one saved item',
      'Open attachments later from the item detail',
    ],
    note: 'Open LaterBox and sign in once before your first share from another app.',
  );

  static const _organizeStep = _TutorialStep(
    icon: Icons.inbox_rounded,
    title: 'Keep Inbox focused',
    description: 'Open a saved item to read it, add a note, star it, or place it in a collection.',
    details: [
      'Use filters to narrow by content type',
      'Archive an item when you finish it',
      'Find archived items later in Library',
    ],
    note:
        'Search checks titles, URLs, summaries, and your notes from one place.',
  );

  static const _syncStep = _TutorialStep(
    icon: Icons.sync_rounded,
    title: 'Continue on another device',
    description: 'Sign in with the same account to keep your saves and organization in sync.',
    details: [
      'New saves appear on your connected devices',
      'Native apps keep a local copy for offline use',
      'Pending changes sync when your connection returns',
    ],
    note: 'LaterBox is local first. Your native library remains useful even when you are offline.',
  );
}

class _TutorialStep {
  const _TutorialStep({
    required this.icon,
    required this.title,
    required this.description,
    required this.details,
    this.shortcutLabel,
    this.shortcut,
    this.note,
  });

  final IconData icon;
  final String title;
  final String description;
  final List<String> details;
  final String? shortcutLabel;
  final String? shortcut;
  final String? note;
}
