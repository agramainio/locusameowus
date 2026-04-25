import 'package:flutter/material.dart';

Widget buildPlatformPhotoImage({
  required String url,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Image.network(
      url,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;

        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return const ColoredBox(color: Colors.black);
      },
    ),
  );
}

void preloadPlatformPhotoImage({
  required String url,
  required BuildContext context,
}) {
  precacheImage(NetworkImage(url), context, onError: (_, _) {});
}
