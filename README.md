# Personal Task Manager (Flutter)

Home assignment for the **Mobile App Developer** recruitment process at GoOnline.  

A mobile application for creating, organizing, and tracking daily tasks.  
It uses a local SQLite database, deadline reminders, and a weather widget based on the user's location.

## Tech Stack

- **Flutter** / Dart  
- **SQLite**: `sqflite` (Android) + `sqflite_common_ffi` (Linux dev)  
- **Notifications**: `awesome_notifications`  
- **Weather integration**: `http`, `geolocator`, OpenWeatherMap API  
- **UI**: Material 3

## Requirements

- Flutter 3.x 
- Android SDK 
- JDK 11

## Quick Start

```bash
# 1) Clone repository
git clone https://github.com/DanielChydz/todo-flutter.git
cd todo-flutter

# 2) Install dependencies
flutter pub get

# 3) (Linux only) SQLite FFI
# main() already includes platform handling, but ensure you have:
#   sqflite_common_ffi in pubspec
#   sqfliteFfiInit()
#   databaseFactory = databaseFactoryFfi

# 4) Run on Android
flutter run
```

# Notifications setup

If notifications don’t show up:

- Disable battery optimizations (“Unrestricted”)
- Check if the channel is not muted in system settings

Notifications required some additional work and configuration during development, and there may still be edge cases or device-specific issues that need further refinement.

# Weather widget
- Integrated with OpenWeatherMap API
- API key is currently hard-coded for demonstration purposes
- Displays current temperature, city, and weather icon based on the user’s location

# Build
```bash
# Debug (default)
flutter run

# Release APK
flutter build apk --release
```

# Tested on
- Linux Mint 22.1 (Ubuntu 24.04 LTS)
- Android 13

### The application has not been tested on iOS and is currently intended for Android devices only. Full functionality is guaranteed only on Android.

# Dev notes
This project was developed within a limited timeframe as part of a recruitment assignment.
Possible areas for further improvement include:

- Refactoring and code cleanup
- Unit and widget testing
- More advanced error handling
- Auto-refresh and caching for the weather widget

Nevertheless, the application demonstrates the required functionality:
task management with deadlines, local storage, notifications, and optional weather integration.
