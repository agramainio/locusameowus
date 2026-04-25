import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'photo_image.dart';

const startupImageUrl =
    'https://firebasestorage.googleapis.com/v0/b/locusameowus.firebasestorage.app/o/img%2Fimage1.png?alt=media&token=6c0b85b1-fe11-4070-9420-28a028f1136a';
const photoCount = 1812;
const firebaseBatchSize = 50;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

Future<List<String>> loadFirebaseImageUrls() async {
  final listedUrls = await loadListedFirebaseImageUrls();

  if (listedUrls.isNotEmpty) {
    return listedUrls;
  }

  return loadGeneratedFirebaseImageUrls();
}

Future<List<String>> loadListedFirebaseImageUrls() async {
  final storageRef = FirebaseStorage.instance.ref('cats');
  final imageUrls = <String>[];
  String? pageToken;

  try {
    do {
      final page = await storageRef.list(
        ListOptions(maxResults: 1000, pageToken: pageToken),
      );

      final pageUrls = await Future.wait(
        page.items.map((item) => item.getDownloadURL()),
      );

      imageUrls.addAll(pageUrls);
      pageToken = page.nextPageToken;
    } while (pageToken != null);
  } catch (error) {
    debugPrint('Storage list failed, falling back to generated paths: $error');
  }

  return imageUrls;
}

Future<List<String>> loadGeneratedFirebaseImageUrls() async {
  final storage = FirebaseStorage.instance;
  final imageUrls = <String>[];

  for (var start = 1; start <= photoCount; start += firebaseBatchSize) {
    final end = min(start + firebaseBatchSize - 1, photoCount);
    final batchIndexes = [for (var i = start; i <= end; i++) i];
    final batchUrls = await Future.wait(
      batchIndexes.map((index) async {
        final photoNumber = index.toString().padLeft(5, '0');
        final photoRef = storage.ref('cats/romeo_$photoNumber.jpg');

        try {
          return await photoRef.getDownloadURL();
        } catch (_) {
          return null;
        }
      }),
    );

    imageUrls.addAll(batchUrls.nonNulls);
  }

  return imageUrls;
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
  const PhotoViewerScreen({
    super.key,
    this.loadImageUrls = loadFirebaseImageUrls,
  });

  final Future<List<String>> Function() loadImageUrls;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final Random random = Random();

  List<String> imageUrls = [];
  bool isLoading = true;

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  Future<void> loadImages() async {
    try {
      final loadedUrls = await widget.loadImageUrls();
      loadedUrls.shuffle(random);

      if (!mounted) return;

      setState(() {
        imageUrls = loadedUrls;
        isLoading = false;
        currentIndex = 0;
      });
      debugPrint('Loaded ${imageUrls.length} images from Firebase Storage');
      debugPrint('Shuffle order: ${imageUrls.map(photoName).join(', ')}');

      if (imageUrls.length > 1) {
        WidgetsBinding.instance.addPostFrameCallback((_) => preloadNextImage());
      }
    } catch (error) {
      debugPrint('Failed to load images from Firebase Storage: $error');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  int get nextIndex {
    if (imageUrls.isEmpty) return 0;

    return (currentIndex + 1) % imageUrls.length;
  }

  void showNextImage() {
    if (imageUrls.isEmpty) return;

    setState(() {
      if (currentIndex == imageUrls.length - 1) {
        final currentUrl = imageUrls[currentIndex];
        imageUrls.shuffle(random);

        if (imageUrls.first == currentUrl && imageUrls.length > 1) {
          final firstUrl = imageUrls[0];
          imageUrls[0] = imageUrls[1];
          imageUrls[1] = firstUrl;
        }

        currentIndex = 0;
      } else {
        currentIndex += 1;
      }
    });
    debugPrint(
      'Showing ${photoName(imageUrls[currentIndex])} '
      '(${currentIndex + 1}/${imageUrls.length})',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => preloadNextImage());
  }

  String photoName(String url) {
    final objectPath = Uri.decodeComponent(Uri.parse(url).pathSegments.last);

    return objectPath.split('/').last;
  }

  void preloadNextImage() {
    if (!mounted || imageUrls.length < 2) return;

    preloadPhotoImage(url: imageUrls[nextIndex], context: context);
  }

  Widget buildBody() {
    if (isLoading) {
      return buildPhotoImage(url: startupImageUrl, onTap: () {});
    }

    if (imageUrls.isEmpty) {
      return buildPhotoImage(url: startupImageUrl, onTap: () {});
    }

    return buildPhotoImage(url: imageUrls[currentIndex], onTap: showNextImage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(child: buildBody()),
    );
  }
}
