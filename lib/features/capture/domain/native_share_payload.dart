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

  static NativeSharePayload? fromMap(Map<dynamic, dynamic> map) {
    final id = map['id'] as String?;
    if (id == null || id.isEmpty) return null;
    final textValue = (map['text'] as String?)?.trim();
    final paths = (map['filePaths'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .where((value) => value.isNotEmpty)
        .toList();
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
