# File Manager Pro

A professional Android File Manager application built with Flutter, inspired by Google Files UI and functionality.

## Features

### 🏠 Home Screen
- **Bottom Navigation**: Clean, Browse, Share tabs
- **Material Design 3**: Modern, clean interface
- **Dark/Light Mode**: System theme support

### 📁 Browse Tab
- File browsing with folder navigation
- File categories (Images, Videos, Audio, Documents, APKs)
- Search functionality
- Storage information display

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

The app requires the following permissions:

- **READ_EXTERNAL_STORAGE**: Read files from device storage
- **WRITE_EXTERNAL_STORAGE**: Write/delete files to storage  
- **MANAGE_EXTERNAL_STORAGE**: Full storage access (Android 11+)
- **QUERY_ALL_PACKAGES**: List installed apps
- **REQUEST_INSTALL_PACKAGES**: Install APK files

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
│   │   └── browse_screen.dart       # File browser
│   ├── clean/
│   │   └── clean_screen.dart        # Storage cleaner
│   └── share/
│       └── share_screen.dart        # File sharing
├── services/
│   └── permission_service.dart     # Permission handling
└── main.dart                        # App entry point
```

## Dependencies

- **flutter_riverpod**: State management
- **google_fonts**: Typography
- **permission_handler**: Android permissions
- **path_provider**: File system paths
- **share_plus**: File sharing
- **open_file**: Open files with external apps
- **device_info_plus**: Device information
- **animations**: Smooth transitions

## Troubleshooting

### Build Issues
- **Enable Developer Mode** on Windows for symlink support
- **Update Flutter SDK**: `flutter upgrade`
- **Clean build**: `flutter clean && flutter pub get`

### Permission Issues
- Grant storage permissions when prompted
- For Android 11+, enable "All files access" in settings

### Performance Issues
- Use Release builds for better performance
- Enable R8 shrinking for release builds

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
