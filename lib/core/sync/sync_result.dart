class SyncResult {
  const SyncResult({
    required this.pushed,
    required this.pulled,
    required this.failed,
    this.skipped = false,
  });

  const SyncResult.skipped()
    : pushed = 0,
      pulled = 0,
      failed = 0,
      skipped = true;

  final int pushed;
  final int pulled;
  final int failed;
  final bool skipped;

  bool get succeeded => !skipped && failed == 0;
}
