import 'package:flutter/material.dart';

import '../../attachments/data/attachment_file_picker.dart';

class MacosQuickCaptureField extends StatefulWidget {
  const MacosQuickCaptureField({
    super.key,
    required this.controller,
    required this.selectedFiles,
    required this.returnAt,
    required this.onChanged,
    required this.onSave,
    required this.onPickAttachments,
    required this.onRemoveAttachment,
    required this.onReturnAtChanged,
    this.sourceLabel,
    this.isSaving = false,
  });

  final TextEditingController controller;
  final List<PickedAttachmentFile> selectedFiles;
  final DateTime? returnAt;
  final String? sourceLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onSave;
  final VoidCallback onPickAttachments;
  final ValueChanged<int> onRemoveAttachment;
  final ValueChanged<DateTime?> onReturnAtChanged;
  final bool isSaving;

  @override
  State<MacosQuickCaptureField> createState() => _MacosQuickCaptureFieldState();
}

class _MacosQuickCaptureFieldState extends State<MacosQuickCaptureField> {
  final _focusNode = FocusNode();
  int _step = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  DateTime _tomorrow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1, 9);
  }

  DateTime _weekend() {
    final now = DateTime.now();
    final days = (DateTime.saturday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day + (days == 0 ? 7 : days), 10);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSave = (widget.controller.text.trim().isNotEmpty || widget.selectedFiles.isNotEmpty) && !widget.isSaving;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Card(
          margin: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.add_box_outlined),
                const SizedBox(width: 10),
                Text('Add to LaterBox', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('⌘↵ to save', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
              ]),
              const SizedBox(height: 20),
              Row(children: List.generate(3, (index) => Expanded(child: _StepTab(
                label: ['Capture', 'Schedule', 'Details'][index],
                selected: _step == index,
                done: _step > index,
                onTap: () => setState(() => _step = index),
              )))),
              const SizedBox(height: 20),
              if (_step == 0) ...[
                if (widget.sourceLabel != null) Text('Selected from ${widget.sourceLabel}', style: theme.textTheme.labelMedium),
                if (widget.sourceLabel != null) const SizedBox(height: 8),
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  minLines: 5,
                  maxLines: 8,
                  onChanged: widget.onChanged,
                  decoration: const InputDecoration(hintText: 'Paste a link, write a note, or drop an idea…', border: OutlineInputBorder()),
                ),
              ] else if (_step == 1) ...[
                Text('When should LaterBox return this?', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _ReturnPreset(label: 'Inbox now', value: null, selected: widget.returnAt == null, onSelect: widget.onReturnAtChanged),
                  _ReturnPreset(label: 'Tomorrow', value: _tomorrow(), selected: false, onSelect: widget.onReturnAtChanged),
                  _ReturnPreset(label: 'Weekend', value: _weekend(), selected: false, onSelect: widget.onReturnAtChanged),
                  _ReturnPreset(label: 'Someday', value: DateTime.now().add(const Duration(days: 30)), selected: false, onSelect: widget.onReturnAtChanged),
                ]),
              ] else ...[
                Text('Attachments', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                OutlinedButton.icon(onPressed: widget.onPickAttachments, icon: const Icon(Icons.attach_file_rounded), label: const Text('Attach files')),
                const SizedBox(height: 8),
                for (var i = 0; i < widget.selectedFiles.length; i++) ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(widget.selectedFiles[i].name, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(onPressed: () => widget.onRemoveAttachment(i), icon: const Icon(Icons.close_rounded)),
                ),
                if (widget.selectedFiles.isEmpty) Text('No files attached. Links and notes are enriched after saving.', style: theme.textTheme.bodySmall),
              ],
              const SizedBox(height: 24),
              Row(children: [
                if (_step > 0) TextButton(onPressed: () => setState(() => _step--), child: const Text('Back')),
                const Spacer(),
                if (_step < 2) OutlinedButton(onPressed: () => setState(() => _step++), child: const Text('Continue')),
                const SizedBox(width: 8),
                FilledButton.icon(onPressed: canSave ? widget.onSave : null, icon: widget.isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.check_rounded), label: Text(widget.isSaving ? 'Saving…' : 'Save to LaterBox')),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _StepTab extends StatelessWidget {
  const _StepTab({required this.label, required this.selected, required this.done, required this.onTap});
  final String label;
  final bool selected;
  final bool done;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 9), alignment: Alignment.center,
    decoration: BoxDecoration(color: selected ? Theme.of(context).colorScheme.primaryContainer : null, border: Border(bottom: BorderSide(color: selected ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, width: 2))),
    child: Text('${done ? '✓ ' : ''}$label', style: TextStyle(fontWeight: selected ? FontWeight.w800 : FontWeight.w600)),
  ));
}

class _ReturnPreset extends StatelessWidget {
  const _ReturnPreset({required this.label, required this.value, required this.selected, required this.onSelect});
  final String label;
  final DateTime? value;
  final bool selected;
  final ValueChanged<DateTime?> onSelect;
  @override
  Widget build(BuildContext context) => ChoiceChip(label: Text(label), selected: selected, onSelected: (_) => onSelect(value));
}
