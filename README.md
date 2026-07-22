# logi_z407_remote

Control Logitech Z407 speakers over BLE using Flutter.

## Build on a Mac

1. Install Flutter and Xcode on the Mac.
2. Install CocoaPods if needed:
   - `sudo gem install cocoapods`
3. Open Terminal in this project folder.
4. Run:
   - `flutter pub get`
   - `cd ios`
   - `pod install`
   - `cd ..`
5. Open the Xcode workspace:
   - `open ios/Runner.xcworkspace`
6. In Xcode, select the Runner target and choose your Apple Developer team.
7. Set a unique bundle identifier if needed (for example `com.yourname.z407remote`).
8. Connect your iPhone and press Run.

## Notes
- The app uses the proprietary Logitech Z407 BLE service and characteristic UUIDs.
- Bluetooth permissions are declared in the iOS plist.
