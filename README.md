# Code Capture

A Flutter app for taking a series of photos and finding QR codes and barcodes in those photos. Tap **Start**, capture photos with the shutter or by tapping the preview, then tap **Stop** to view the scan results.

## Features

- Live camera preview with Start, shutter, and Stop controls.
- Queued photo capture, so quick repeated taps are processed in order.
- Flash disabled and camera audio disabled.
- QR and barcode detection using Google ML Kit.
- Results summary and filters for all photos, QR codes, barcodes, and photos without codes.
- Copy decoded values and open captured photos full-screen with zoom.

Each photo is scanned after it is saved. Stop waits for queued captures and scans before opening the results screen.

## Project structure

```text
assets/icons/                     Editable SVG logo sources for the launcher icon
android/app/src/main/res/         Generated Android launcher icons and adaptive layers
ios/Runner/Assets.xcassets/       Generated iOS AppIcon asset catalog
lib/
  app/app_theme.dart              Shared application theme
  app/constants/app_colors.dart   Shared colors
  app/constants/app_text.dart     Shared static text
  main.dart                       App entry point, portrait orientation, and GetMaterialApp
  models/capture_item.dart        Captured photo and decoded code models
  services/scan_service.dart      Google ML Kit barcode scanning wrapper
  viewmodels/results_view_model.dart  Results filtering and counts using GetX
  views/camera_view.dart          Camera preview, capture flow, and camera state
  views/results_view.dart         Scan results and full-screen photo views
  widgets/action_buttons.dart     Shared Start/Stop and shutter buttons
```

## Packages

| Package | Purpose |
| --- | --- |
| [`camera`](https://pub.dev/packages/camera) | Camera preview and photo capture |
| [`google_mlkit_barcode_scanning`](https://pub.dev/packages/google_mlkit_barcode_scanning) | On-device QR code and barcode detection |
| [`get`](https://pub.dev/packages/get) | GetX state management and navigation |
| [`launcher_icons`](https://pub.dev/packages/launcher_icons) | Generates native launcher icons from the logo sources |

`launcher_icons` is a maintained launcher-icon generator. Its configuration in `pubspec.yaml` creates Android legacy and adaptive icons (including the Android 13 monochrome layer), and the iOS AppIcon catalog. See the [package guide](https://pub.dev/packages/launcher_icons), [Android configuration](https://github.com/Quasiflo/launcher_icons/blob/main/doc/android.md), and [iOS configuration](https://github.com/Quasiflo/launcher_icons/blob/main/doc/ios.md).

## Application logo and launcher icons

The logo is a vector mark with a camera body and lens, teal scan brackets, and barcode lines. It uses the app's dark navy and teal palette.

### Editable source files

- `assets/icons/code_capture_icon.svg` — square icon artwork with its opaque background; used for iOS and Android legacy launcher images.
- `assets/icons/code_capture_foreground.svg` — transparent artwork layer for Android adaptive icons.
- `assets/icons/code_capture_monochrome.svg` — single-color silhouette for Android themed icons.

### Generated platform assets

- Android density-specific launcher images: `android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Android adaptive icon definition and layers: `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` and `android/app/src/main/res/drawable-*/ic_launcher_*.png`.
- Android adaptive background color: `android/app/src/main/res/values/colors.xml`.
- iOS icon sizes and catalog metadata: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`.

The Android manifest already references `@mipmap/ic_launcher`, and the iOS Xcode project already references the `AppIcon` asset catalog. The generator updates those existing icon assets and keeps platform behavior unchanged. The iOS 1024×1024 App Store icon is generated without transparency.

### Regenerate icons

After editing any SVG source, from the project root run:

```bash
flutter pub get
dart run launcher_icons
```

The launcher configuration is under `launcher_icons:` in `pubspec.yaml`. Android uses a dark navy adaptive background, a separate transparent foreground, and a monochrome foreground. iOS icons are generated from the opaque square artwork.

## Run the app

Use a Flutter SDK whose bundled Dart SDK satisfies the constraint in `pubspec.yaml` (`^3.13.3`). For camera testing, use a physical device or a simulator with camera support.

```bash
flutter pub get
flutter run
```

## Build

Android debug APK:

```bash
flutter build apk --debug
```

The APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

For release:

```bash
flutter build apk --release
```

## Verification status

- `flutter analyze` reports no errors. It reports one informational lint in `lib/views/camera_view.dart` about showing the existing snackbar after an async wait.
- `flutter build apk --debug` completed successfully after generating the launcher icons.
- The iOS icon catalog was checked: all 21 image entries reference existing files, and the 1024×1024 icon is opaque.
- `flutter build ios --no-codesign` currently stops during CocoaPods dependency resolution. The project targets iOS 15.0, while `google_mlkit_barcode_scanning` requires at least iOS 15.5. This project setting was left unchanged during the icon work.
- The existing `test/widget_test.dart` is the default counter smoke test and expects counter UI that this camera app does not contain; it fails for that expectation.

## Notes

- Code detection runs on each saved photo; keep codes in focus and fully inside the frame for reliable results.
- The app is locked to portrait orientation.
- After changing an installed app icon, uninstall and reinstall the app if the launcher continues showing a cached icon.
