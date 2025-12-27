# SnapNote Voice

An offline-first note capturing app for Android that allows users to create notes using voice or camera input.

## Features

- **Fully Offline**: No internet connection required
- **Voice Notes**: Record and convert speech to text
- **Camera OCR**: Extract text from images using offline OCR
- **Text Notes**: Create and edit notes with text input
- **Local Storage**: All data stored locally using Hive
- **Privacy First**: No data sharing, analytics, or cloud sync
- **Material 3 Design**: Modern, flat UI with light/dark mode support

## Package Name

`com.snapnote.voice`

## Permissions

The app only requests:
- Microphone (for voice notes)
- Camera (for text scanning)

No other permissions are requested.

## Architecture

- **State Management**: Provider
- **Local Storage**: Hive
- **Voice Recognition**: speech_to_text (offline)
- **OCR**: google_mlkit_text_recognition (offline)
- **UI Framework**: Flutter with Material 3

## Building

```bash
flutter pub get
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/
│   └── note.dart            # Note data model
├── providers/
│   ├── notes_provider.dart  # Notes state management
│   └── theme_provider.dart  # Theme state management
├── screens/
│   ├── notes_list_screen.dart    # Main notes list
│   ├── note_editor_screen.dart   # Note editor
│   ├── camera_screen.dart        # Camera OCR screen
│   └── settings_screen.dart      # Settings
├── services/
│   ├── storage_service.dart      # Hive storage
│   ├── voice_service.dart        # Speech-to-text
│   └── camera_service.dart       # Camera & OCR
└── theme/
    └── app_theme.dart            # Material 3 themes
```

## Company Information

**Company Name**: MINORMEND CONSTRUCTION PRIVATE LIMITED  
**Support Email**: minormendcon1997@gmail.com

## License

Private - All rights reserved
