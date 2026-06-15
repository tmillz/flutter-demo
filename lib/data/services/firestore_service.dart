import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post.dart';
import '../models/reaction.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _postsCollection = _firestore.collection('posts');
  static final CollectionReference _reactionsCollection = _firestore.collection('reactions');

  // Get all posts as a stream
  static Stream<List<Post>> getPosts() {
    return _postsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Post.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get reactions for a specific post
  static Stream<List<Reaction>> getReactionsForPost(String postId) {
    return _reactionsCollection
        .where('postId', isEqualTo: postId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Reaction.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Add a new post (admin only - will be enforced by Firestore rules)
  static Future<void> addPost(Post post) async {
    await _postsCollection.doc(post.id).set(post.toMap());
  }

  // Add a reaction to a post
  static Future<void> addReaction(Reaction reaction) async {
    await _reactionsCollection.doc(reaction.id).set(reaction.toMap());
  }

  // Remove a reaction
  static Future<void> removeReaction(String reactionId) async {
    await _reactionsCollection.doc(reactionId).delete();
  }

  // Check if user has already reacted with a specific emoji on a post
  static Stream<bool> hasUserReacted(String postId, String userId, String emoji) {
    return _reactionsCollection
        .where('postId', isEqualTo: postId)
        .where('userId', isEqualTo: userId)
        .where('emoji', isEqualTo: emoji)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}
