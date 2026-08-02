class Post {
  final String id;
  final String content;
  final String? embedUrl;
  final DateTime createdAt;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;

  Post({
    required this.id,
    required this.content,
    this.embedUrl,
    required this.createdAt,
    required this.authorId,
    required this.authorName,
    this.authorPhotoUrl,
  });

  factory Post.fromMap(Map<String, dynamic> map, String documentId) {
    final rawCreatedAt = map['createdAt'];
    final createdAt = switch (rawCreatedAt) {
      DateTime d => d,
      final dynamic v when v != null => (v as dynamic).toDate() as DateTime,
      _ => DateTime.now(),
    };

    final rawEmbed = map['embedUrl'];
    final embedUrl = rawEmbed is String && rawEmbed.trim().isNotEmpty
        ? rawEmbed
        : null;

    return Post(
      id: documentId,
      content: (map['content'] as String?)?.trim() ?? '',
      embedUrl: embedUrl,
      createdAt: createdAt,
      authorId: (map['authorId'] as String?) ?? 'unknown',
      authorName: (map['authorName'] as String?) ?? 'Anonymous',
      authorPhotoUrl: map['authorPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'content': content,
      'embedUrl': embedUrl,
      'createdAt': createdAt,
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
    };
  }
}
