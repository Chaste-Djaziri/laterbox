import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../attachments/data/attachment_file_picker.dart';
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
  final List<PickedAttachmentFile> _selectedFiles = [];
  List<AttachmentImportFailure> _fileFailures = const [];
  bool _saving = false;

  Future<void> _chooseFiles() async {
    final platform = Theme.of(context).platform;
    final isMobile = !kIsWeb &&
        (platform == TargetPlatform.iOS || platform == TargetPlatform.android);

    final AttachmentPickerSource? source;
    if (isMobile) {
      source = await showModalBottomSheet<AttachmentPickerSource>(
        context: context,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Choose attachment source',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.folder_open_rounded,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: const Text(
                      'Files',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle:
                        const Text('Browse PDFs, documents, archives & files'),
                    onTap: () => Navigator.of(context)
                        .pop(AttachmentPickerSource.files),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_library_rounded,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                    title: const Text(
                      'Photo & Video Gallery',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle:
                        const Text('Pick photos and videos from your gallery'),
                    onTap: () => Navigator.of(context)
                        .pop(AttachmentPickerSource.gallery),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      source = AttachmentPickerSource.files;
    }

    if (source == null || !mounted) return;

    try {
      final files = await ref
          .read(attachmentFilePickerProvider)
          .pickFiles(source: source);
      if (!mounted || files.isEmpty) return;
      setState(() {
        for (final file in files) {
          final duplicate = _selectedFiles.any(
            (selected) =>
                selected.name == file.name && selected.size == file.size,
          );
          if (!duplicate) _selectedFiles.add(file);
        }
        _fileFailures = const [];
        _error = null;
      });
    } catch (error, stackTrace) {
      debugPrint('[LaterBox Attachments] file picker failed: $error');
      debugPrintStack(stackTrace: stackTrace);
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

    var popped = false;
    try {
      if (_selectedFiles.isNotEmpty) {
        final result = kIsWeb
            ? await ref
                  .read(webAttachmentImportServiceProvider)
                  .importFiles(files: _selectedFiles, text: _controller.text)
            : await (await ref.read(attachmentImportServiceProvider.future))
                  .importFiles(
                    sourcePaths: _selectedFiles
                        .map((file) => file.path)
                        .whereType<String>()
                        .toList(),
                    text: _controller.text,
                  );
        if (!mounted) return;
        if (!result.saved) {
          setState(() => _fileFailures = result.failures);
          return;
        }

        final messenger = ScaffoldMessenger.of(context);
        popped = true;
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
      if (mounted) {
        popped = true;
        Navigator.of(context).pop();
      }
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Could not save this item. Try again.');
    } finally {
      if (mounted && !popped) {
        setState(() => _saving = false);
      }
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
                      'Save to laterbox',
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
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  hintText: 'https://...',
                  errorText: _error,
                ),
                onSubmitted: _saving ? null : (_) => _save(),
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
                  (file) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      onPressed: _saving
                          ? null
                          : () => setState(() {
                              _selectedFiles.remove(file);
                              _fileFailures = const [];
                            }),
                      tooltip: 'Remove ${file.name}',
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
