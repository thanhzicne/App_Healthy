# 🩺 app_healthcare

**app_healthcare** là ứng dụng Flutter giúp người dùng theo dõi và quản lý các chỉ số sức khỏe hàng ngày như bước đi, lượng nước uống, cân nặng và thông tin cá nhân.  
Ứng dụng phù hợp cho người dùng muốn duy trì lối sống lành mạnh và kiểm soát thể trạng của mình một cách khoa học.

---

## 🚀 Tính năng chính

- 👣 **Theo dõi bước chân (Steps Tracker)**:  
  Ghi nhận và hiển thị số bước đi mỗi ngày.

- 💧 **Theo dõi lượng nước uống (Water Tracker)**:  
  Giúp bạn đảm bảo đủ lượng nước cần thiết mỗi ngày.

- ⚖️ **Theo dõi cân nặng (Weight Tracker)**:  
  Ghi lại thay đổi cân nặng theo thời gian.

- 👤 **Quản lý hồ sơ cá nhân (Profile Management)**:  
  Cập nhật và lưu trữ thông tin sức khỏe cơ bản.

- 🏠 **Trang chủ tổng quan (Home Screen)**:  
  Hiển thị tổng hợp các chỉ số sức khỏe trong ngày.

- 🔐 **Đăng ký & Đăng nhập (Register/Login)**:  
  Hỗ trợ xác thực người dùng bằng Firebase Authentication.

---

## 🧩 Cấu trúc thư mục

```
app_healthcare
├─ .metadata
├─ .qodo
├─ analysis_options.yaml
├─ android
│  ├─ .gradle
│  │  ├─ 8.12
│  │  │  ├─ checksums
│  │  │  │  ├─ checksums.lock
│  │  │  │  ├─ md5-checksums.bin
│  │  │  │  └─ sha1-checksums.bin
│  │  │  ├─ executionHistory
│  │  │  │  ├─ executionHistory.bin
│  │  │  │  └─ executionHistory.lock
│  │  │  ├─ expanded
│  │  │  ├─ fileChanges
│  │  │  │  └─ last-build.bin
│  │  │  ├─ fileHashes
│  │  │  │  ├─ fileHashes.bin
│  │  │  │  ├─ fileHashes.lock
│  │  │  │  └─ resourceHashesCache.bin
│  │  │  ├─ gc.properties
│  │  │  └─ vcsMetadata
│  │  ├─ buildOutputCleanup
│  │  │  ├─ buildOutputCleanup.lock
│  │  │  ├─ cache.properties
│  │  │  └─ outputFiles.bin
│  │  ├─ noVersion
│  │  │  └─ buildLogic.lock
│  │  └─ vcs-1
│  │     └─ gc.properties
│  ├─ app
│  │  ├─ build.gradle.kts
│  │  ├─ google-services.json
│  │  └─ src
│  │     ├─ debug
│  │     │  └─ AndroidManifest.xml
│  │     ├─ main
│  │     │  ├─ AndroidManifest.xml
│  │     │  ├─ java
│  │     │  │  └─ io
│  │     │  │     └─ flutter
│  │     │  │        └─ plugins
│  │     │  │           └─ GeneratedPluginRegistrant.java
│  │     │  ├─ kotlin
│  │     │  │  └─ com
│  │     │  │     └─ example
│  │     │  │        └─ app_healthcare
│  │     │  │           └─ MainActivity.kt
│  │     │  └─ res
│  │     │     ├─ drawable
│  │     │     │  └─ launch_background.xml
│  │     │     ├─ drawable-v21
│  │     │     │  └─ launch_background.xml
│  │     │     ├─ mipmap-hdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-mdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xxhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ mipmap-xxxhdpi
│  │     │     │  └─ ic_launcher.png
│  │     │     ├─ values
│  │     │     │  └─ styles.xml
│  │     │     └─ values-night
│  │     │        └─ styles.xml
│  │     └─ profile
│  │        └─ AndroidManifest.xml
│  ├─ build.gradle.kts
│  ├─ gradle
│  │  └─ wrapper
│  │     ├─ gradle-wrapper.jar
│  │     └─ gradle-wrapper.properties
│  ├─ gradle.properties
│  ├─ gradlew
│  ├─ gradlew.bat
│  ├─ local.properties
│  └─ settings.gradle.kts
├─ firebase.json
├─ ios
│  ├─ Flutter
│  │  ├─ AppFrameworkInfo.plist
│  │  ├─ Debug.xcconfig
│  │  ├─ ephemeral
│  │  │  ├─ flutter_lldbinit
│  │  │  └─ flutter_lldb_helper.py
│  │  ├─ flutter_export_environment.sh
│  │  ├─ Generated.xcconfig
│  │  └─ Release.xcconfig
│  ├─ Runner
│  │  ├─ AppDelegate.swift
│  │  ├─ Assets.xcassets
│  │  │  ├─ AppIcon.appiconset
│  │  │  │  ├─ Contents.json
│  │  │  │  ├─ Icon-App-1024x1024@1x.png
│  │  │  │  ├─ Icon-App-20x20@1x.png
│  │  │  │  ├─ Icon-App-20x20@2x.png
│  │  │  │  ├─ Icon-App-20x20@3x.png
│  │  │  │  ├─ Icon-App-29x29@1x.png
│  │  │  │  ├─ Icon-App-29x29@2x.png
│  │  │  │  ├─ Icon-App-29x29@3x.png
│  │  │  │  ├─ Icon-App-40x40@1x.png
│  │  │  │  ├─ Icon-App-40x40@2x.png
│  │  │  │  ├─ Icon-App-40x40@3x.png
│  │  │  │  ├─ Icon-App-60x60@2x.png
│  │  │  │  ├─ Icon-App-60x60@3x.png
│  │  │  │  ├─ Icon-App-76x76@1x.png
│  │  │  │  ├─ Icon-App-76x76@2x.png
│  │  │  │  └─ Icon-App-83.5x83.5@2x.png
│  │  │  └─ LaunchImage.imageset
│  │  │     ├─ Contents.json
│  │  │     ├─ LaunchImage.png
│  │  │     ├─ LaunchImage@2x.png
│  │  │     ├─ LaunchImage@3x.png
│  │  │     └─ README.md
│  │  ├─ Base.lproj
│  │  │  ├─ LaunchScreen.storyboard
│  │  │  └─ Main.storyboard
│  │  ├─ GeneratedPluginRegistrant.h
│  │  ├─ GeneratedPluginRegistrant.m
│  │  ├─ Info.plist
│  │  └─ Runner-Bridging-Header.h
│  ├─ Runner.xcodeproj
│  │  ├─ project.pbxproj
│  │  ├─ project.xcworkspace
│  │  │  ├─ contents.xcworkspacedata
│  │  │  └─ xcshareddata
│  │  │     ├─ IDEWorkspaceChecks.plist
│  │  │     └─ WorkspaceSettings.xcsettings
│  │  └─ xcshareddata
│  │     └─ xcschemes
│  │        └─ Runner.xcscheme
│  ├─ Runner.xcworkspace
│  │  ├─ contents.xcworkspacedata
│  │  └─ xcshareddata
│  │     ├─ IDEWorkspaceChecks.plist
│  │     └─ WorkspaceSettings.xcsettings
│  └─ RunnerTests
│     └─ RunnerTests.swift
├─ lib
│  ├─ firebase_options.dart
│  ├─ main.dart
│  ├─ models
│  │  ├─ steps_model.dart
│  │  ├─ user_model.dart
│  │  ├─ water_intake_model.dart
│  │  └─ weight_model.dart
│  ├─ navigation
│  │  └─ bottom_nav.dart
│  ├─ providers
│  │  ├─ steps_provider.dart
│  │  ├─ user_provider.dart
│  │  ├─ water_provider.dart
│  │  └─ weight_provider.dart
│  ├─ screens
│  │  ├─ home_screen.dart
│  │  ├─ login_screen.dart
│  │  ├─ profile_screen.dart
│  │  ├─ register_screen.dart
│  │  ├─ steps_screen.dart
│  │  ├─ water_screen.dart
│  │  └─ weight_screen.dart
│  ├─ utils
│  │  ├─ colors.dart
│  │  ├─ constants.dart
│  │  └─ helpers.dart
│  └─ widgets
│     ├─ chart_widget.dart
│     ├─ custom_app_bar.dart
│     ├─ info_card.dart
│     ├─ progress_ring.dart
│     └─ quick_action_button.dart
├─ linux
│  ├─ CMakeLists.txt
│  ├─ flutter
│  │  ├─ CMakeLists.txt
│  │  ├─ ephemeral
│  │  │  └─ .plugin_symlinks
│  │  │     └─ path_provider_linux
│  │  ├─ generated_plugins.cmake
│  │  ├─ generated_plugin_registrant.cc
│  │  └─ generated_plugin_registrant.h
│  └─ runner
│     ├─ CMakeLists.txt
│     ├─ main.cc
│     ├─ my_application.cc
│     └─ my_application.h
├─ macos
│  ├─ Flutter
│  │  ├─ ephemeral
│  │  │  ├─ Flutter-Generated.xcconfig
│  │  │  └─ flutter_export_environment.sh
│  │  ├─ Flutter-Debug.xcconfig
│  │  ├─ Flutter-Release.xcconfig
│  │  └─ GeneratedPluginRegistrant.swift
│  ├─ Runner
│  │  ├─ AppDelegate.swift
│  │  ├─ Assets.xcassets
│  │  │  └─ AppIcon.appiconset
│  │  │     ├─ app_icon_1024.png
│  │  │     ├─ app_icon_128.png
│  │  │     ├─ app_icon_16.png
│  │  │     ├─ app_icon_256.png
│  │  │     ├─ app_icon_32.png
│  │  │     ├─ app_icon_512.png
│  │  │     ├─ app_icon_64.png
│  │  │     └─ Contents.json
│  │  ├─ Base.lproj
│  │  │  └─ MainMenu.xib
│  │  ├─ Configs
│  │  │  ├─ AppInfo.xcconfig
│  │  │  ├─ Debug.xcconfig
│  │  │  ├─ Release.xcconfig
│  │  │  └─ Warnings.xcconfig
│  │  ├─ DebugProfile.entitlements
│  │  ├─ Info.plist
│  │  ├─ MainFlutterWindow.swift
│  │  └─ Release.entitlements
│  ├─ Runner.xcodeproj
│  │  ├─ project.pbxproj
│  │  ├─ project.xcworkspace
│  │  │  └─ xcshareddata
│  │  │     └─ IDEWorkspaceChecks.plist
│  │  └─ xcshareddata
│  │     └─ xcschemes
│  │        └─ Runner.xcscheme
│  ├─ Runner.xcworkspace
│  │  ├─ contents.xcworkspacedata
│  │  └─ xcshareddata
│  │     └─ IDEWorkspaceChecks.plist
│  └─ RunnerTests
│     └─ RunnerTests.swift
├─ pubspec.lock
├─ pubspec.yaml
├─ README.md
├─ test
│  └─ widget_test.dart
├─ web
│  ├─ favicon.png
│  ├─ icons
│  │  ├─ Icon-192.png
│  │  ├─ Icon-512.png
│  │  ├─ Icon-maskable-192.png
│  │  └─ Icon-maskable-512.png
│  ├─ index.html
│  └─ manifest.json
└─ windows
   ├─ CMakeLists.txt
   ├─ flutter
   │  ├─ CMakeLists.txt
   │  ├─ ephemeral
   │  │  └─ .plugin_symlinks
   │  │     ├─ cloud_firestore
   │  │     ├─ firebase_auth
   │  │     ├─ firebase_core
   │  │     └─ path_provider_windows
   │  ├─ generated_plugins.cmake
   │  ├─ generated_plugin_registrant.cc
   │  └─ generated_plugin_registrant.h
   └─ runner
      ├─ CMakeLists.txt
      ├─ flutter_window.cpp
      ├─ flutter_window.h
      ├─ main.cpp
      ├─ resource.h
      ├─ resources
      │  └─ app_icon.ico
      ├─ runner.exe.manifest
      ├─ Runner.rc
      ├─ utils.cpp
      ├─ utils.h
      ├─ win32_window.cpp
      └─ win32_window.h

```

---

## ⚙️ Công nghệ sử dụng

- **Flutter** (Dart)
- **Firebase Authentication** – Đăng nhập/đăng ký
- **Firebase Realtime Database / Firestore** – Lưu trữ dữ liệu sức khỏe
- **Provider** – Quản lý trạng thái ứng dụng
- **Material Design 3 (MD3)** – Giao diện người dùng hiện đại

---

## 🧠 Hướng dẫn cài đặt

1. **Clone dự án:**
   ```bash
   git clone https://github.com/thanhzicne/App_Healthy
   
2. **flutter pub get**
3. **flutter run**
