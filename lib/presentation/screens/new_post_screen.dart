// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/firestore_service.dart';
import '../../data/models/post.dart';
import 'pick_post_image.dart';
import '../widgets/app_brand_title.dart';

class NewPostScreen extends StatefulWidget {
  const NewPostScreen({super.key});

  @override
  State<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _embedUrlController = TextEditingController();
  bool _isSubmitting = false;
  final String _adminEmail = 'terrymil1981@gmail.com';
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void dispose() {
    _contentController.dispose();
    _embedUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in again before uploading.'),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      final downloadUrl = await pickPostImage(
        user.uid,
      ).timeout(const Duration(seconds: 120));

      if (downloadUrl == null || !mounted) return;
      setState(() {
        _imageUrl = downloadUrl;
        _embedUrlController.text = downloadUrl;
      });
    } on FirebaseException catch (e) {
      final message = e.message ?? e.code;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Storage error: $message')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if user is admin
      if (user.email != _adminEmail) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only admin can create posts')),
          );
          context.pop();
        }
        return;
      }

      final post = Post(
        createdAt: DateTime.now(),
        authorId: user.uid,
        authorName: user.displayName ?? 'Anonymous',
        id: '',
        content: _contentController.text.trim(),
        embedUrl: _embedUrlController.text.trim().isEmpty
            ? null
            : _embedUrlController.text.trim(),
      );

      await FirestoreService.addPost(post);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 80,
        title: const AppBrandTitle(
          title: 'New Post',
          subtitle: 'share something new',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Post Content',
                  hintText: 'What\'s on your mind?',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter some content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _pickImage,
                icon: _isUploading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.image),
                label: Text(_isUploading ? 'Uploading...' : 'Pick Image'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Text('Failed to load image'),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _imageUrl = null;
                      _embedUrlController.clear();
                    });
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove Image'),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _embedUrlController,
                decoration: InputDecoration(
                  labelText: 'Embed URL (optional)',
                  hintText: 'https://example.com',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    // Basic URL validation
                    final urlPattern = RegExp(
                      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
                    );
                    if (!urlPattern.hasMatch(value.trim())) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPost,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Create Post'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
