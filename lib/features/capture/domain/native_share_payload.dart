import 'dart:io';

class NativeSharePayload {
  const NativeSharePayload({
    required this.id,
    required this.filePaths,
    this.text,
    this.createdAt,
  });

  final String id;
  final String? text;
  final List<String> filePaths;
  final DateTime? createdAt;

  bool get hasFiles => filePaths.isNotEmpty;

  static String? extractFilePathFromUri(String input) {
    final trimmed = input.trim();
    if (trimmed.startsWith('file://')) {
      try {
        final uri = Uri.parse(trimmed);
        final path = uri.toFilePath();
        if (path.isNotEmpty) return path;
      } catch (_) {
        final raw = trimmed.replaceFirst('file://', '');
        if (raw.isNotEmpty) return raw;
      }
    } else if (trimmed.startsWith('file:/')) {
      final raw = trimmed.replaceFirst(RegExp(r'^file:/+'), '/');
      if (raw.isNotEmpty) return raw;
    }
    return null;
  }

  static NativeSharePayload? fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'] as String?;
    if (id == null || id.isEmpty) return null;
    var textValue = (map['text'] as String?)?.trim();
    final paths = (map['filePaths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();

    if (textValue != null && textValue.isNotEmpty) {
      final extractedPath = extractFilePathFromUri(textValue);
      if (extractedPath != null) {
        if (!paths.contains(extractedPath)) {
          paths.add(extractedPath);
        }
        textValue = null;
      }
    }

    if ((textValue == null || textValue.isEmpty) && paths.isEmpty) return null;
    final createdAtValue = map['createdAt'] as String?;
    return NativeSharePayload(
      id: id,
      text: textValue == null || textValue.isEmpty ? null : textValue,
      filePaths: paths,
      createdAt: createdAtValue == null
          ? null
          : DateTime.tryParse(createdAtValue),
    );
  }
}
