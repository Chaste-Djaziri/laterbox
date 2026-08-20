import 'package:flutter/material.dart';

/// The quick capture input. Keyboard shortcuts (`⌘↵` / `Esc`) are handled by
/// [QuickCaptureScreen] around this widget so they work regardless of focus.
///
/// The [TextEditingController] is owned by the screen so the Save button and
/// the `⌘↵` shortcut read the exact current value through one submit path.
class QuickCaptureField extends StatefulWidget {
  const QuickCaptureField({
    super.key,
    required this.controller,
    required this.sourceLabel,
    required this.onChanged,
    required this.onSave,
  });

  final TextEditingController controller;

  /// Frontmost app at capture time, shown when content came from a selection.
  final String? sourceLabel;

  final ValueChanged<String> onChanged;
  final VoidCallback onSave;

  @override
  State<QuickCaptureField> createState() => _QuickCaptureFieldState();
}

class _QuickCaptureFieldState extends State<QuickCaptureField> {
  final _focusNode = FocusNode();

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceLabel = widget.sourceLabel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.quickreply_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'LaterBox Quick Capture',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Text(
                '⌘↵ to save',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          if (sourceLabel != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Selected from $sourceLabel',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: 2,
            maxLines: 4,
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              hintText: 'Paste a link or type anything…',
              border: OutlineInputBorder(),
            ),
            onChanged: widget.onChanged,
            onSubmitted: (_) => widget.onSave(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: widget.onSave,
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Save'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}