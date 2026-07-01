import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/post.dart';
import '../../data/models/reaction.dart';
import '../../data/services/firestore_service.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isAdmin;

  const PostCard({super.key, required this.post, required this.isAdmin});

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
    _reactionsSubscription =
        FirestoreService.getReactionsForPost(widget.post.id).listen((
          reactions,
        ) {
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
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to add emoji reactions')),
        );
      }
      return;
    }

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

  TextStyle _emojiFallbackStyle({FontWeight? fontWeight}) {
    return TextStyle(
      fontWeight: fontWeight,
      fontFamilyFallback: const [
        'Apple Color Emoji',
        'Segoe UI Emoji',
        'Noto Color Emoji',
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final emojiCounts = _emojiCounts;
    final isNarrowScreen = MediaQuery.sizeOf(context).width < 600;
    final cardHorizontalMargin = isNarrowScreen ? 8.0 : 16.0;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: cardHorizontalMargin,
        vertical: 8,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
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
                  const Icon(
                    Icons.admin_panel_settings,
                    size: 20,
                    color: Colors.blue,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (widget.post.embedUrl != null) ...[
              const SizedBox(height: 12),
              _EmbedWidget(url: widget.post.embedUrl!),
            ],
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Text(
                  'React: ',
                  style: _emojiFallbackStyle(fontWeight: FontWeight.bold),
                ),
                ...['👍', '❤️', '😂', '😮', '😢', '🎉'].map((emoji) {
                  final count = emojiCounts[emoji] ?? 0;
                  final hasReacted = _userReactions.contains(emoji);
                  return InkWell(
                    onTap: () => _toggleReaction(emoji),
                    child: Chip(
                      label: Text(
                        '$emoji $count',
                        style: _emojiFallbackStyle(),
                      ),
                      backgroundColor: hasReacted
                          ? Colors.blue.withValues(alpha: 0.2)
                          : null,
                      side: hasReacted ? BorderSide(color: Colors.blue) : null,
                    ),
                  );
                }),
              ],
            ),
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

/// Renders an embed URL as a YouTube player, image, or tappable link.
class _EmbedWidget extends StatelessWidget {
  const _EmbedWidget({required this.url});

  final String url;

  bool get _isYouTube {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com/watch') ||
        lower.contains('youtu.be/') ||
        lower.contains('youtube.com/shorts/') ||
        lower.contains('youtube.com/embed/');
  }

  bool get _looksLikeImage {
    final lower = url.toLowerCase();
    if (lower.contains('firebasestorage.googleapis.com')) return true;
    if (lower.contains('firebasestorage.app')) return true;
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    if (_isYouTube) {
      return _YouTubeEmbed(url: url);
    }
    if (_looksLikeImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, _) => _LinkFallback(url: url),
        ),
      );
    }
    return _LinkFallback(url: url);
  }
}

class _YouTubeEmbed extends StatefulWidget {
  const _YouTubeEmbed({required this.url});

  final String url;

  @override
  State<_YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<_YouTubeEmbed> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.url) ?? '';
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        mute: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: YoutubePlayer(controller: _controller, aspectRatio: 16 / 9),
    );
  }
}

class _LinkFallback extends StatelessWidget {
  const _LinkFallback({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(url);
        if (uri != null) {
          // Reuse the app's existing URL opener.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Opening: $url')));
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.link, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                url,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
