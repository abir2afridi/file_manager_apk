# File Manager Pro Changelog

A professional Android File Manager application built with Flutter, inspired by Google Files UI and functionality.

## Features

### 🏠 Home Screen
- **Bottom Navigation**: Clean, Browse, Share tabs
- **Material Design 3**: Modern, clean interface
- **Dark/Light Mode**: System theme support

### 📁 Browse Tab
- File browsing with folder navigation
- File categories (Images, Videos, Audio, Documents, APKs, Archives)
- Search functionality
- Storage information display
- **In‑App Viewers**: Open images, videos, audio, and documents without leaving the app
  - Image gallery & fullscreen viewer with zoom/pan
  - Video player with controls and playlist support
  - Audio player with queue and background playback
  - Document viewer for PDF, TXT, DOCX (fallback to external apps)
- **ZIP Toolkit**: Compress and extract archives with progress indicators

### 🧹 Clean Tab
- Storage analysis
- Large file detection
- Junk file cleanup
- Cache management

### 📤 Share Tab
- Easy file sharing
- Multiple file selection
- Share to various apps

## Requirements

- **Flutter**: 3.10.0 or higher
- **Dart**: 3.10.7 or higher
- **Android**: API 21+ (Android 5.0)
- **Permissions**: Storage access required

## Installation

### 1. Clone the Repository
```bash
git clone <repository-url>
cd file_manager_pro
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Run the App
```bash
flutter run
```

### 4. Build APK
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```

## Android Studio Setup

1. **Open Android Studio**
2. **File → Open** → Select the project folder
3. **Wait for Gradle sync** to complete
4. **Select device/emulator** from the dropdown
5. **Click Run** button or press `Shift+F10`

## Permissions Required

The app requests the following permissions based on Android version:

- **READ_EXTERNAL_STORAGE / WRITE_EXTERNAL_STORAGE**: Legacy storage access (Android < 10)
- **MANAGE_EXTERNAL_STORAGE**: Full storage access (Android 11+)
- **QUERY_ALL_PACKAGES**: List installed apps
- **REQUEST_INSTALL_PACKAGES**: Install APK files
- **Android 13+ granular media permissions** (photos, videos, audio) for media libraries

## Project Structure

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart          # App themes
├── features/
│   ├── home/
│   │   └── home_screen.dart         # Main navigation
│   ├── browse/
│   │   └── browse_screen.dart       # File browser & tools entry
│   ├── clean/
│   │   └── clean_screen.dart        # Storage cleaner
│   ├── share/
│   │   └── share_screen.dart        # File sharing
│   ├── media/
│   │   ├── screens/
│   │   │   ├── image_gallery_screen.dart
│   │   │   ├── image_viewer_screen.dart
│   │   │   ├── video_library_screen.dart
│   │   │   ├── video_player_screen.dart
│   │   │   ├── audio_library_screen.dart
│   │   │   └── audio_player_screen.dart
│   │   └── widgets/
│   │       └── media_thumbnail.dart
│   ├── documents/
│   │   └── screens/
│   │       └── document_viewer_screen.dart
│   ├── zip/
│   │   └── screens/
│   │       └── zip_tool_screen.dart
│   └── file_explorer/
│       └── file_list_screen.dart
├── services/
│   ├── permission_service.dart     # Permission handling (Android 13+ media)
│   ├── file_service.dart           # File operations
│   ├── media_library_service.dart  # Media scanning (isolates)
│   ├── document_service.dart       # Document parsing (PDF/TXT/DOCX)
│   ├── audio_playback_service.dart # Audio playback wrapper
│   ├── zip_service.dart            # ZIP compression/extraction
│   ├── file_type_resolver.dart     # MIME/type resolution
│   └── viewer_launcher.dart        # Centralized viewer routing
├── providers/
│   ├── media_library_providers.dart
│   ├── document_providers.dart
│   └── audio_playback_provider.dart
├── models/
│   ├── file_model.dart
│   ├── media_asset.dart
│   └── document_models.dart
└── main.dart                        # App entry point
```

## Dependencies

- **flutter_riverpod**: State management
- **google_fonts**: Typography
- **permission_handler**: Android permissions (including Android 13+ media)
- **path_provider**: File system paths
- **share_plus**: File sharing
- **open_filex**: Open files with external apps (fallback)
- **device_info_plus**: Device information
- **animations**: Smooth transitions

### Media & Document Viewers
- **photo_view**: Image zoom/pan and fullscreen viewer
- **video_player**: In‑app video playback
- **just_audio**: Audio playback with background support
- **audio_session**: Audio session management
- **pdfx**: PDF rendering
- **mime**: MIME type detection
- **archive**: ZIP compression/extraction and DOCX parsing
- **xml**: DOCX XML parsing
- **path**: Path utilities

## Troubleshooting

### Build Issues
- **Enable Developer Mode** on Windows for symlink support
- **Update Flutter SDK**: `flutter upgrade`
- **Clean build**: `flutter clean && flutter pub get`

### Permission Issues
- Grant storage permissions when prompted
- For Android 11+, enable "All files access" in settings
- On Android 13+, grant individual media permissions (Photos, Videos, Audio) for media libraries

### Performance Issues
- Use Release builds for better performance
- Enable R8 shrinking for release builds
- Media scanning runs in isolates to avoid UI freezes

### Viewer Fallbacks
- In‑app viewers support common formats (images, videos, audio, PDF, TXT, DOCX)
- Unsupported formats automatically open with external apps via `open_filex`
- Errors in in‑app rendering also trigger external app fallback

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.

## Support

For issues and feature requests, please create an issue in the repository.
