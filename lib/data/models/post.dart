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
    return Post(
      id: documentId,
      content: map['content'] as String,
      embedUrl: map['embedUrl'] as String?,
      createdAt: (map['createdAt'] as dynamic).toDate(),
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String,
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
