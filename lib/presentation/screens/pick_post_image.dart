import 'pick_post_image_io.dart'
    if (dart.library.html) 'pick_post_image_web.dart';

Future<String?> pickPostImage(String userId) => pickPostImageImpl(userId);
