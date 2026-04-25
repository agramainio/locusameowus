import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locusameowus/main.dart';

void main() {
  testWidgets('tap advances to the next image', (WidgetTester tester) async {
    const expectedUrls = {
      'https://example.com/photo-1.jpg',
      'https://example.com/photo-2.jpg',
    };

    await tester.pumpWidget(
      MaterialApp(
        home: PhotoViewerScreen(
          loadImageUrls: () async => expectedUrls.toList(),
        ),
      ),
    );
    await tester.pump();

    Image image = tester.widget(find.byType(Image));
    final firstUrl = (image.image as NetworkImage).url;
    expect(expectedUrls, contains(firstUrl));

    await tester.tap(find.byType(GestureDetector));
    await tester.pump();
    tester.takeException();

    image = tester.widget(find.byType(Image));
    final secondUrl = (image.image as NetworkImage).url;
    expect(expectedUrls, contains(secondUrl));
    expect(secondUrl, isNot(firstUrl));
  });
}
