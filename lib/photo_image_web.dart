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
  late final web.HTMLImageElement image;
  late final web.EventListener tapListener;
  late final web.EventListener resizeListener;

  @override
  void initState() {
    super.initState();

    web.document.getElementById(_photoLayerId)?.remove();

    layer = web.HTMLDivElement()..id = _photoLayerId;
    image = web.HTMLImageElement()
      ..alt = ''
      ..decoding = 'async'
      ..loading = 'eager';
    tapListener = ((web.Event event) {
      event.preventDefault();
      widget.onTap();
    }).toJS;
    resizeListener = ((web.Event _) {
      updateLayer();
    }).toJS;

    layer.addEventListener('pointerup', tapListener);
    web.window.addEventListener('resize', resizeListener);
    layer.appendChild(image);
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
    web.window.removeEventListener('resize', resizeListener);
    layer.remove();
    super.dispose();
  }

  void updateLayer() {
    final width = web.window.innerWidth;
    final height = web.window.innerHeight;

    layer.style.cssText =
        '''
      position: fixed;
      inset: 0;
      left: 0;
      top: 0;
      width: ${width}px;
      height: ${height}px;
      z-index: 2147483647;
      overflow: hidden;
      background-color: black;
      cursor: pointer;
      user-select: none;
      touch-action: manipulation;
    ''';

    image.src = widget.url;
    image.style.cssText =
        '''
      position: absolute;
      left: 0;
      top: 0;
      width: ${width}px;
      height: ${height}px;
      object-fit: contain;
      object-position: center center;
      display: block;
      background: black;
      max-width: none;
      max-height: none;
      -webkit-user-drag: none;
      user-select: none;
    ''';
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.expand();
  }
}
