import 'package:flutter/widgets.dart';

import 'photo_image_stub.dart'
    if (dart.library.js_interop) 'photo_image_web.dart';

Widget buildPhotoImage({required String url, required VoidCallback onTap}) {
  return buildPlatformPhotoImage(url: url, onTap: onTap);
}

void preloadPhotoImage({required String url, required BuildContext context}) {
  preloadPlatformPhotoImage(url: url, context: context);
}
