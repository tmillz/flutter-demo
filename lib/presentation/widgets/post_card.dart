import 'dart:async';

import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/post.dart';
import '../../data/models/reaction.dart';
import '../../data/services/firestore_service.dart';
import '../theme/app_typography.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isAdmin;

  const PostCard({super.key, required this.post, required this.isAdmin});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  static const _reactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🎉'];

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

  TextStyle _emojiFallbackStyle({required TextStyle base}) {
    return TextStyle(
      fontSize: base.fontSize,
      fontWeight: base.fontWeight,
      letterSpacing: base.letterSpacing,
      color: base.color,
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
                        style: AppTypography.postAuthor(
                          Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Text(
                        _formatDate(widget.post.createdAt),
                        style: AppTypography.postMeta(
                          Theme.of(context).textTheme.bodySmall,
                        ),
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
              style: AppTypography.postBody(
                Theme.of(context).textTheme.bodyLarge,
              ),
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
                  style: _emojiFallbackStyle(
                    base: AppTypography.reactionLabel(),
                  ),
                ),
                ..._reactionEmojis.map((emoji) {
                  final count = emojiCounts[emoji] ?? 0;
                  final hasReacted = _userReactions.contains(emoji);
                  return InkWell(
                    onTap: () => _toggleReaction(emoji),
                    child: Chip(
                      label: Text(
                        '$emoji $count',
                        style: _emojiFallbackStyle(
                          base: AppTypography.reactionChipLabel(),
                        ),
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
    final today = DateTime(now.year, now.month, now.day);
    final postDay = DateTime(date.year, date.month, date.day);
    final dayDifference = today.difference(postDay).inDays;

    if (dayDifference == 0) return 'Today at ${_formatTime(date)}';
    if (dayDifference == 1) return 'Yesterday at ${_formatTime(date)}';

    final month = _monthAbbreviation(date.month);
    if (date.year == now.year) {
      return '$month ${date.day} at ${_formatTime(date)}';
    }
    return '$month ${date.day}, ${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour12 = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour12:$minute $period';
  }

  String _monthAbbreviation(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
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
      return _YouTubeLiteEmbed(url: url);
    }
    if (_looksLikeImage) {
      final pixelRatio = MediaQuery.devicePixelRatioOf(context);
      final cacheWidth = (MediaQuery.sizeOf(context).width * pixelRatio)
          .round()
          .clamp(640, 1600)
          .toInt();
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.network(
            url,
            width: double.infinity,
            fit: BoxFit.cover,
            cacheWidth: cacheWidth,
            filterQuality: FilterQuality.low,
            errorBuilder: (context, error, _) => _LinkFallback(url: url),
          ),
        ),
      );
    }
    return _LinkFallback(url: url);
  }
}

class _YouTubeLiteEmbed extends StatefulWidget {
  const _YouTubeLiteEmbed({required this.url});

  final String url;

  @override
  State<_YouTubeLiteEmbed> createState() => _YouTubeLiteEmbedState();
}

class _YouTubeLiteEmbedState extends State<_YouTubeLiteEmbed> {
  bool _loadPlayer = false;

  @override
  Widget build(BuildContext context) {
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (videoId == null || videoId.isEmpty) {
      return _LinkFallback(url: widget.url);
    }
    if (_loadPlayer) {
      return _YouTubeEmbed(url: widget.url);
    }

    final thumbnailUrl = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              thumbnailUrl,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              errorBuilder: (context, _, _) =>
                  const ColoredBox(color: Colors.black12),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.black.withValues(alpha: 0.28),
                child: InkWell(
                  onTap: () => setState(() => _loadPlayer = true),
                  child: const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 64,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _YouTubeEmbed extends StatefulWidget {
  const _YouTubeEmbed({required this.url});

  final String url;

  @override
  State<_YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<_YouTubeEmbed> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final videoId = YoutubePlayerController.convertUrlToId(widget.url);
    if (videoId == null || videoId.isEmpty) return;
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
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _LinkFallback(url: widget.url);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(controller: controller),
      ),
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
