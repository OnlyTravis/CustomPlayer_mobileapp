# CustomPlayer

My First Flutter Project

A music playing Android app that supports both video and audio playing.
(Useable but still WIP)

## Features
* Supports both Audio & Video playing
* Supports background playing
* Customizable song tags
* Change individual song author display
* Change individual song volume
* Create Playlists of your own
* Create Playlists automatically based on tag filters
* PIP mode (WIP)
* Export / Import Database
* Customizable pages background image
* Customizable theme / theme color

## Installation (manual)
Make sure flutter is install on your device.
Clone this repo with
```bash
git clone https://github.com/OnlyTravis/CustomPlayer_mobile-app.git
```
Connect to your phone via USB
You can check if your phone is connected via
```bash
flutter devices
```
After your phone is connected, run the following commands
```bash
# Android OS with aarch64 architecture
flutter build apk --release --target-platform android-arm64
flutter install
```