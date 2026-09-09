class ScreenCaptureContext {
  const ScreenCaptureContext({
    this.application,
    this.url,
    this.title,
    this.selectedText,
    this.highlightUrl,
  });

  final String? application;
  final String? url;
  final String? title;
  final String? selectedText;
  final String? highlightUrl;

  bool get hasUrl => url != null && url!.isNotEmpty;
  bool get hasSelection => selectedText != null && selectedText!.trim().isNotEmpty;
  bool get hasHighlightUrl => highlightUrl != null && highlightUrl!.isNotEmpty;

  String? get frontmostApp => application;
  String? get activeUrl => url;
  String? get activeTitle => title;

  /// Prefer highlight URL if text is selected from a web page, otherwise page URL, otherwise null.
  String? get targetUrl => highlightUrl ?? url;

  factory ScreenCaptureContext.fromMap(Map<dynamic, dynamic> map) {
    return ScreenCaptureContext(
      application: map['application'] as String?,
      url: map['url'] as String?,
      title: map['title'] as String?,
      selectedText: map['selectedText'] as String?,
      highlightUrl: map['highlightUrl'] as String?,
    );
  }
}
