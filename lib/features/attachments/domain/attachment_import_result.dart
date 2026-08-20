enum AttachmentImportFailureCode {
  unsupportedType,
  tooLarge,
  emptyFile,
  unreadable,
  mimeMismatch,
  sourceChanged,
  copyFailed,
  verificationFailed,
  databaseFailed,
}

class AttachmentImportFailure {
  const AttachmentImportFailure({
    required this.displayName,
    required this.sourcePath,
    required this.code,
    this.details,
  });

  final String displayName;
  final String sourcePath;
  final AttachmentImportFailureCode code;
  final String? details;
}

class AttachmentImportResult {
  const AttachmentImportResult({
    required this.itemId,
    required this.attachmentIds,
    required this.failures,
  });

  final String? itemId;
  final List<String> attachmentIds;
  final List<AttachmentImportFailure> failures;

  bool get saved => itemId != null && attachmentIds.isNotEmpty;
}
