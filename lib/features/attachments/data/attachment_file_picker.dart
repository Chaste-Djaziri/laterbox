import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../domain/attachment_file_policy.dart';

abstract interface class AttachmentFilePicker {
  Future<List<PickedAttachmentFile>> pickFiles();
}

class PickedAttachmentFile {
  const PickedAttachmentFile({
    required this.name,
    required this.size,
    this.path,
    this.bytes,
  });

  final String name;
  final int size;
  final String? path;
  final Uint8List? bytes;
}

class NativeAttachmentFilePicker implements AttachmentFilePicker {
  const NativeAttachmentFilePicker();

  @override
  Future<List<PickedAttachmentFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: attachmentMimeTypes.keys.toSet().toList(),
      withData: kIsWeb,
      withReadStream: false,
    );
    if (result == null) return const [];
    return result.files
        .map(
          (file) => PickedAttachmentFile(
            name: file.name,
            size: file.size,
            path: file.path,
            bytes: file.bytes,
          ),
        )
        .toList();
  }
}
