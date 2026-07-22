# logi_z407_remote

Control Logitech Z407 speakers over BLE using Flutter.

## Build on a Mac for sideloading with a free Apple ID

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
6. In Xcode, sign in with your free Apple ID:
   - Xcode → Settings → Accounts → + → Apple ID
7. Select the Runner target and enable signing:
   - Signing & Capabilities
   - turn on “Automatically manage signing”
   - choose your personal team
8. If Xcode asks for a bundle identifier, use something unique such as `com.yourname.z407remote`.
9. Connect your iPhone and press Run.

### SideStore / free Apple ID workflow
- This project is set up for a standard Apple ID and sideloading rather than App Store distribution.
- After the build succeeds, you can install the generated app on your device with SideStore.
- SideStore will usually require re-signing periodically, so expect to refresh the app every 7 days.
- If Xcode says the app is not signed, make sure the Apple ID is added under Xcode Accounts and that the Runner target is using the personal team.

## Notes
- The app uses the proprietary Logitech Z407 BLE service and characteristic UUIDs.
- Bluetooth permissions are declared in the iOS plist.
