import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

enum AttachmentPickerSource {
  files,
  gallery,
}

abstract interface class AttachmentFilePicker {
  Future<List<PickedAttachmentFile>> pickFiles({
    AttachmentPickerSource source = AttachmentPickerSource.files,
  });
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
  Future<List<PickedAttachmentFile>> pickFiles({
    AttachmentPickerSource source = AttachmentPickerSource.files,
  }) async {
    final fileType = switch (source) {
      AttachmentPickerSource.files => FileType.any,
      AttachmentPickerSource.gallery => FileType.media,
    };
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: fileType,
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
