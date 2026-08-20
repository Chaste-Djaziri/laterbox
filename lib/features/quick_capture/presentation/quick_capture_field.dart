import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class QuickCaptureField extends StatefulWidget {
  const QuickCaptureField({
    super.key,
    required this.initialText,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final String? initialText;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  State<QuickCaptureField> createState() => _QuickCaptureFieldState();
}

class _QuickCaptureFieldState extends State<QuickCaptureField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter, meta: true): _SaveIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          _SaveIntent: CallbackAction<_SaveIntent>(
            onInvoke: (_) => widget.onSave(),
          ),
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => widget.onCancel(),
          ),
        },
        child: Padding(
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
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'LaterBox Quick Capture',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '⌘↵ to save',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 2,
                maxLines: 5,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveIntent extends Intent {
  const _SaveIntent();
}