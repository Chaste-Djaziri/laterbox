class LaterBoxItem {
  const LaterBoxItem({
    required this.id,
    this.url,
    this.title,
    this.text,
    this.type = 'unknown',
    this.favorite = false,
    this.archived = false,
    required this.createdAt,
  });

  final String id;
  final String? url;
  final String? title;
  final String? text;
  final String type;
  final bool favorite;
  final bool archived;
  final DateTime createdAt;
}
