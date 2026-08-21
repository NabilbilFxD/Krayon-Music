# Krayon Music

<p align="center">
  <b>An open-source, zero-ad audio streaming application built for high-fidelity sound.</b>
</p>

<p align="center">
  <a href="https://flutter.dev"><img src="https://img.shields.io/badge/Framework-Flutter-02569B?logo=flutter&logoColor=white" alt="Flutter"></a>
  <a href="https://dart.dev"><img src="https://img.shields.io/badge/Language-Dart_79%25-0175C2?logo=dart&logoColor=white" alt="Dart"></a>
  <a href="https://isocpp.org"><img src="https://img.shields.io/badge/Core-C%2B%2B-00599C?logo=c%2B%2B&logoColor=white" alt="C++"></a>
  <a href="https://github.com/NabilbilFxD/Krayon-Music/releases"><img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android&logoColor=white" alt="Android"></a>
  <a href="#license"><img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License"></a>
</p>

<p align="center">
  <a href="#overview">Overview</a> •
  <a href="#core-features">Core Features</a> •
  <a href="#tech-stack">Tech Stack</a> •
  <a href="#installation">Installation</a> •
  <a href="#developer-setup">Developer Setup</a> •
  <a href="#maintainer">Maintainer</a>
</p>

---

## Overview

**Krayon Music** is a lightweight, high-performance mobile application designed for listeners who value uninterrupted, crystal-clear audio. Many modern music platforms degrade audio quality or disrupt the listening experience with invasive ads and mandatory subscription paywalls. 

Krayon Music solves this by providing a completely free, ad-free environment powered by a native C++ audio rendering pipeline wrapped in a responsive Flutter interface.

---

## Core Features

- 🎧 **High-Fidelity Audio Core**: Low-latency playback engine optimized using C/C++ native bindings.
- 🚫 **Zero Ad Interruptions**: Clean interface with no pop-ups, audio banners, or third-party trackers.
- 💰 **100% Free & Open Source**: Full access to all features without paywalls, accounts, or premium tiers.
- 📱 **Native Performance**: Smooth, modern UI designed with Flutter for fluid animations and low memory usage.

---

## Tech Stack

The repository codebase distribution:

```text
Dart        ██████████████████████████████████  79.0%
C++         █████                               10.5%
CMake       ████                                 8.1%
Swift       █                                    1.1%
HTML/C      █                                    1.2%

Frontend & App Logic: Dart / Flutter

Audio Engine & System Binding: C++ / C

Build System: CMake / Gradle

Platform Layer: Swift (iOS) & Kotlin/Java (Android)

Installation
Android (APK)
Open the Releases page on this repository.

Download the latest .apk asset file.

Open the downloaded file on your device and confirm the installation.

Developer Setup
To build and run the source code locally:

Prerequisites
Flutter SDK (stable channel)

Android Studio / Android SDK (for Android build tools)

Git

Steps
Bash
# Clone the project repository
git clone [https://github.com/NabilbilFxD/Krayon-Music.git](https://github.com/NabilbilFxD/Krayon-Music.git)

# Navigate into the directory
cd Krayon-Music

# Fetch project dependencies
flutter pub get

# Execute the application on a connected device/emulator
flutter run
To output a release build:

Bash
flutter build apk --release
Maintainer
License
This project is licensed under the MIT License. See the LICENSE file for details.
