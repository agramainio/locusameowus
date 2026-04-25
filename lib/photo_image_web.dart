import 'dart:js_interop';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

const _photoLayerId = 'locusameowus-photo-layer';

Widget buildPlatformPhotoImage({
  required String url,
  required VoidCallback onTap,
}) {
  return _FullscreenWebPhoto(url: url, onTap: onTap);
}

void preloadPlatformPhotoImage({
  required String url,
  required BuildContext context,
}) {
  final image = web.HTMLImageElement()
    ..src = url
    ..decoding = 'async'
    ..loading = 'eager';

  image.decode().toDart.catchError((_) => null);
}

class _FullscreenWebPhoto extends StatefulWidget {
  const _FullscreenWebPhoto({required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  State<_FullscreenWebPhoto> createState() => _FullscreenWebPhotoState();
}

class _FullscreenWebPhotoState extends State<_FullscreenWebPhoto> {
  late final web.HTMLDivElement layer;
  late final web.EventListener tapListener;

  @override
  void initState() {
    super.initState();

    web.document.getElementById(_photoLayerId)?.remove();

    layer = web.HTMLDivElement()..id = _photoLayerId;
    tapListener = ((web.Event event) {
      event.preventDefault();
      widget.onTap();
    }).toJS;

    layer.addEventListener('pointerup', tapListener);
    web.document.body?.appendChild(layer);
    web.document.body?.style.setProperty('margin', '0');
    web.document.body?.style.setProperty('overflow', 'hidden');

    updateLayer();
  }

  @override
  void didUpdateWidget(_FullscreenWebPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.url != widget.url) {
      updateLayer();
    }
  }

  @override
  void dispose() {
    layer.removeEventListener('pointerup', tapListener);
    layer.remove();
    super.dispose();
  }

  void updateLayer() {
    layer.style.cssText =
        '''
      position: fixed;
      inset: 0;
      left: 0;
      top: 0;
      width: 100vw;
      height: 100vh;
      height: 100dvh;
      min-width: 100vw;
      min-height: 100vh;
      min-height: 100dvh;
      z-index: 2147483647;
      overflow: hidden;
      background-color: black;
      background-image: url("${widget.url}");
      background-size: cover;
      background-position: center center;
      background-repeat: no-repeat;
      cursor: pointer;
      user-select: none;
      touch-action: manipulation;
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
