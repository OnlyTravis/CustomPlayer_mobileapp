# CustomPlayer

My First Flutter Project

A music playing Android app that supports both video and audio playing.

## Features
* Supports both Audio & Video playing
* Supports background playing
* Customizable song tags
* Change individual song author display
* Change individual song volume
* Create Playlists of your own
* Create Playlists automatically based on tag filters
* PIP mode 
* Export / Import Database
* Customizable pages background image
* Customizable theme / theme color

## Manual Installation
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
After your phone is connected, run the following commands in the cloned repo
```bash
flutter build apk --release --target-platform android-arm64
flutter install
```