import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'photo_image.dart';

const startupImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/locusameowus.firebasestorage.app/o/img%2Fimage1.png?alt=media&token=6c0b85b1-fe11-4070-9420-28a028f1136a';
const preloadAheadCount = 6;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class PhotoEntry {
  PhotoEntry.fromUrl(this.url) : ref = null;

  PhotoEntry.fromRef(this.ref);

  final Reference? ref;
  String? url;
  Future<String?>? urlFuture;

  String get name {
    final currentUrl = url;

    if (ref != null) return ref!.name;
    if (currentUrl != null) return photoNameFromUrl(currentUrl);

    return 'photo';
  }
}

String photoNameFromUrl(String url) {
  final objectPath = Uri.decodeComponent(Uri.parse(url).pathSegments.last);

  return objectPath.split('/').last;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PhotoViewerScreen(),
    );
  }
}

class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, this.initialImageUrls});

  final List<String>? initialImageUrls;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final Random random = Random();
  final Set<String> preloadedUrls = {};

  List<PhotoEntry> photos = [];
  bool isLoading = true;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    final initialImageUrls = widget.initialImageUrls;

    if (initialImageUrls != null) {
      final initialPhotos = initialImageUrls.map(PhotoEntry.fromUrl).toList()
        ..shuffle(random);

      setState(() {
        photos = initialPhotos;
        isLoading = false;
        currentIndex = 0;
      });

      if (photos.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => preloadUpcomingImages(),
        );
      }

      return;
    }

    try {
      final storageRef = FirebaseStorage.instance.ref('cats');
      String? pageToken;

      do {
        final page = await storageRef.list(
          ListOptions(maxResults: 1000, pageToken: pageToken),
        );
        final items = page.items.toList()..shuffle(random);

        if (!mounted) return;

        setState(() {
          final newPhotos = items.map(PhotoEntry.fromRef).toList();

          if (photos.isEmpty) {
            photos = newPhotos;
          } else {
            photos.addAll(newPhotos);
          }

          isLoading = false;
          currentIndex = currentIndex.clamp(0, photos.length - 1);
        });

        debugPrint('Found ${photos.length} photo refs from Firebase Storage');

        if (photos.isNotEmpty) {
          await resolvePhotoAtIndex(currentIndex);
        }

        if (photos.length > 1) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => preloadUpcomingImages(),
          );
        }

        pageToken = page.nextPageToken;
      } while (pageToken != null);
    } catch (error) {
      debugPrint('Failed to load images from Firebase Storage: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  int get nextIndex {
    if (photos.isEmpty) return 0;

    return (currentIndex + 1) % photos.length;
  }

  void showNextImage() {
    if (photos.isEmpty) return;

    setState(() {
      if (currentIndex == photos.length - 1) {
        final currentPhoto = photos[currentIndex];
        photos.shuffle(random);

        if (photos.first == currentPhoto && photos.length > 1) {
          final firstPhoto = photos[0];
          photos[0] = photos[1];
          photos[1] = firstPhoto;
        }

        currentIndex = 0;
      } else {
        currentIndex += 1;
      }
    });
    debugPrint(
      'Showing ${photos[currentIndex].name} '
      '(${currentIndex + 1}/${photos.length})',
    );

    resolvePhotoAtIndex(currentIndex);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => preloadUpcomingImages(),
    );
  }

  Future<String?> resolvePhotoAtIndex(int index) {
    if (index < 0 || index >= photos.length) {
      return Future.value(null);
    }

    final photo = photos[index];

    if (photo.url != null) {
      return Future.value(photo.url);
    }

    final ref = photo.ref;

    if (ref == null) {
      return Future.value(null);
    }

    photo.urlFuture ??= () async {
      try {
        final url = await ref.getDownloadURL();
        photo.url = url;

        return url;
      } catch (error) {
        debugPrint('Failed to resolve ${ref.fullPath}: $error');

        return null;
      }
    }();

    return photo.urlFuture!.then((url) {
      if (mounted && url != null) {
        setState(() {});
      }

      return url;
    });
  }

  void preloadUpcomingImages() {
    if (!mounted || photos.length < 2) return;

    for (var step = 1; step <= preloadAheadCount; step++) {
      final preloadIndex = (currentIndex + step) % photos.length;

      resolvePhotoAtIndex(preloadIndex).then((url) {
        if (!mounted || url == null) return;

        if (preloadedUrls.add(url)) {
          preloadPhotoImage(url: url, context: context);
        }
      });
    }
  }

  Widget buildBody() {
    if (isLoading) {
      return buildPhotoImage(url: startupImageUrl, onTap: () {});
    }

    if (photos.isEmpty) {
      return buildPhotoImage(url: startupImageUrl, onTap: () {});
    }

    final currentUrl = photos[currentIndex].url;

    if (currentUrl == null) {
      resolvePhotoAtIndex(currentIndex);

      return buildPhotoImage(url: startupImageUrl, onTap: () {});
    }

    return buildPhotoImage(url: currentUrl, onTap: showNextImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: buildBody()),
    );
  }
}
