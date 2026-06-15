class Reaction {
  final String id;
  final String postId;
  final String emoji;
  final String userId;
  final String userName;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.postId,
    required this.emoji,
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  factory Reaction.fromMap(Map<String, dynamic> map, String documentId) {
    return Reaction(
      id: documentId,
      postId: map['postId'] as String,
      emoji: map['emoji'] as String,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      createdAt: (map['createdAt'] as dynamic).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'emoji': emoji,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt,
    };
  }
}
