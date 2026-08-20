import 'package:file_picker/file_picker.dart';

import '../domain/attachment_file_policy.dart';

abstract interface class AttachmentFilePicker {
  Future<List<String>> pickFiles();
}

class NativeAttachmentFilePicker implements AttachmentFilePicker {
  const NativeAttachmentFilePicker();

  @override
  Future<List<String>> pickFiles() async {
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: attachmentMimeTypes.keys.toSet().toList(),
      withData: false,
      withReadStream: false,
    );
    if (result == null) return const [];
    return result.paths.whereType<String>().toList();
  }
}
