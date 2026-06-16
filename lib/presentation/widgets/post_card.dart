import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/models/post.dart';
import '../../data/models/reaction.dart';
import '../../data/services/firestore_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isAdmin;

  const PostCard({
    super.key,
    required this.post,
    required this.isAdmin,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final List<Reaction> _reactions = [];
  final Set<String> _userReactions = {};
  StreamSubscription<List<Reaction>>? _reactionsSubscription;

  @override
  void initState() {
    super.initState();
    _listenToReactions();
  }

  @override
  void dispose() {
    _reactionsSubscription?.cancel();
    super.dispose();
  }

  void _listenToReactions() {
    _reactionsSubscription = FirestoreService.getReactionsForPost(widget.post.id).listen((reactions) {
      if (mounted) {
        setState(() {
          _reactions.clear();
          _reactions.addAll(reactions);
          _userReactions.clear();
          final userId = FirebaseAuth.instance.currentUser?.uid;
          if (userId != null) {
            for (final reaction in reactions) {
              if (reaction.userId == userId) {
                _userReactions.add(reaction.emoji);
              }
            }
          }
        });
      }
    });
  }

  Future<void> _toggleReaction(String emoji) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final hasReacted = _userReactions.contains(emoji);
    
    if (hasReacted) {
      // Find and remove the reaction
      final reactionToRemove = _reactions.firstWhere(
        (r) => r.emoji == emoji && r.userId == user.uid,
      );
      await FirestoreService.removeReaction(reactionToRemove.id);
    } else {
      // Add new reaction
      final reaction = Reaction(
        id: FirebaseFirestore.instance.collection('reactions').doc().id,
        postId: widget.post.id,
        emoji: emoji,
        userId: user.uid,
        userName: user.displayName ?? user.email ?? 'Anonymous',
        createdAt: DateTime.now(),
      );
      await FirestoreService.addReaction(reaction);
    }
  }

  Map<String, int> get _emojiCounts {
    final counts = <String, int>{};
    for (final reaction in _reactions) {
      counts[reaction.emoji] = (counts[reaction.emoji] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final emojiCounts = _emojiCounts;
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: widget.post.authorPhotoUrl != null
                      ? NetworkImage(widget.post.authorPhotoUrl!)
                      : null,
                  child: widget.post.authorPhotoUrl == null
                      ? const Icon(Icons.person, size: 20)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.post.authorName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (widget.isAdmin)
                  const Icon(Icons.admin_panel_settings, size: 20, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(
              widget.post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.post.embedUrl != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Embed: ${widget.post.embedUrl}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Reactions section
            if (user != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text('React: ', style: GoogleFonts.notoColorEmoji(fontWeight: FontWeight.bold)),
                  ...['👍', '❤️', '😂', '😮', '😢', '🎉'].map((emoji) {
                    final count = emojiCounts[emoji] ?? 0;
                    final hasReacted = _userReactions.contains(emoji);
                    return InkWell(
                      onTap: () => _toggleReaction(emoji),
                      child: Chip(
                        label: Text(
                          '$emoji $count',
                          style: GoogleFonts.notoColorEmoji(),
                        ),
                        backgroundColor: hasReacted ? Colors.blue.withValues(alpha: 0.2) : null,
                        side: hasReacted ? BorderSide(color: Colors.blue) : null,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }
}
