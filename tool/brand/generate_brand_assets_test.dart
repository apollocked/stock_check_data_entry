// Renders the logo, launcher icon and splash PNGs from BrandMarkPainter.
//
//   flutter test tool/brand/generate_brand_assets_test.dart
//   dart run flutter_launcher_icons
//
// Run it after changing the mark. It also writes the native splash images
// for Android and iOS; all outputs are committed.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stockly/presentation/widgets/brand/brand_mark_painter.dart';

const _androidRes = 'android/app/src/main/res';
const _iosLaunch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset';

Future<void> _render(String name, int px, BrandMarkPainter painter) async {
  final recorder = ui.PictureRecorder();
  final size = Size.square(px.toDouble());
  painter.paint(Canvas(recorder), size);
  final image = await recorder.endRecording().toImage(px, px);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(name.contains('/') ? name : 'assets/branding/$name');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  test('generate brand assets', () async {
    // iOS, web, desktop and legacy Android icon: square, full bleed tile
    // (each platform applies its own corner mask).
    await _render(
      'logo.png',
      1024,
      const BrandMarkPainter(scale: 0.78, cornerRadius: 0),
    );
    // Android adaptive icon layers.
    await _render(
      'logo_background.png',
      1024,
      const BrandMarkPainter(cornerRadius: 0, showMark: false),
    );
    await _render(
      'logo_foreground.png',
      1024,
      const BrandMarkPainter(background: false, scale: 0.85),
    );
    await _render(
      'logo_monochrome.png',
      1024,
      const BrandMarkPainter(
        background: false,
        scale: 0.85,
        monochrome: Colors.white,
      ),
    );
    // Splash screens: a 120 dp rounded tile for Android < 12 and iOS, and the
    // bare mark for the Android 12+ splash icon (288 dp, drawn on a circle).
    const tile = BrandMarkPainter(scale: 0.8);
    await _render('$_androidRes/drawable-xxxhdpi/splash_logo.png', 480, tile);
    for (final (suffix, px) in [('', 120), ('@2x', 240), ('@3x', 360)]) {
      await _render('$_iosLaunch/LaunchImage$suffix.png', px, tile);
    }
    await _render(
      '$_androidRes/drawable-xxxhdpi/splash_android12.png',
      1152,
      const BrandMarkPainter(background: false, scale: 0.62),
    );
  });
}
