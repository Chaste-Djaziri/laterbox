import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../../attachments/domain/attachment_import_result.dart';
import '../../attachments/presentation/attachment_providers.dart';
import '../domain/capture_payload.dart';
import '../domain/capture_providers.dart';

class CaptureSheet extends ConsumerStatefulWidget {
  const CaptureSheet({super.key});

  @override
  ConsumerState<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends ConsumerState<CaptureSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  final List<String> _selectedFiles = [];
  List<AttachmentImportFailure> _fileFailures = const [];
  bool _saving = false;

  Future<void> _chooseFiles() async {
    try {
      final paths = await ref.read(attachmentFilePickerProvider).pickFiles();
      if (!mounted || paths.isEmpty) return;
      setState(() {
        for (final filePath in paths) {
          if (!_selectedFiles.contains(filePath)) _selectedFiles.add(filePath);
        }
        _fileFailures = const [];
        _error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not open the file picker.');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (_selectedFiles.isNotEmpty) {
        final service = await ref.read(attachmentImportServiceProvider.future);
        final result = await service.importFiles(
          sourcePaths: _selectedFiles,
          text: _controller.text,
        );
        if (!mounted) return;
        if (!result.saved) {
          setState(() => _fileFailures = result.failures);
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        if (result.failures.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(content: Text(_partialSuccessMessage(result))),
          );
        }
        return;
      }
      await ref
          .read(captureServiceProvider)
          .save(
            CapturePayload.fromValue(
              _controller.text,
              source: CaptureSource.manual,
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save this item. Try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: {
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => Navigator.of(context).pop(),
          ),
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + keyboardHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Save to LaterBox',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Paste anything',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  errorText: _error,
                ),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _chooseFiles,
                icon: const Icon(Icons.attach_file_rounded),
                label: const Text('Choose files'),
              ),
              if (_selectedFiles.isNotEmpty) ...[
                const SizedBox(height: 12),
                ..._selectedFiles.map(
                  (filePath) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      path.basename(filePath),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _selectedFiles.remove(filePath);
                              _fileFailures = const [];
                            }),
                      tooltip: 'Remove ${path.basename(filePath)}',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ),
              ],
              if (_fileFailures.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Couldn’t add:',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                ..._fileFailures.map(
                  (failure) => Text(
                    '• ${failure.displayName} — ${_failureReason(failure.code)}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _partialSuccessMessage(AttachmentImportResult result) {
    final lines = <String>[
      'Saved ${result.attachmentIds.length} '
          '${result.attachmentIds.length == 1 ? 'file' : 'files'}',
      '',
      'Couldn’t add:',
      ...result.failures.map(
        (failure) =>
            '• ${failure.displayName} — ${_failureReason(failure.code)}',
      ),
    ];
    return lines.join('\n');
  }

  String _failureReason(AttachmentImportFailureCode code) => switch (code) {
    AttachmentImportFailureCode.unsupportedType => 'unsupported file type',
    AttachmentImportFailureCode.tooLarge =>
      'files larger than 100 MB aren’t supported yet',
    AttachmentImportFailureCode.emptyFile => 'the file is empty',
    AttachmentImportFailureCode.unreadable => 'the file could not be read',
    AttachmentImportFailureCode.mimeMismatch =>
      'the file contents do not match its type',
    AttachmentImportFailureCode.sourceChanged =>
      'the file changed while it was being copied',
    AttachmentImportFailureCode.copyFailed => 'the file could not be copied',
    AttachmentImportFailureCode.verificationFailed =>
      'the copied file could not be verified',
    AttachmentImportFailureCode.databaseFailed =>
      'the attachment could not be saved',
  };
}
