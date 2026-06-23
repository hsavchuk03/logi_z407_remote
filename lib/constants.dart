class LogiConstants {
  static const String serviceUuid = '0000fdc2-0000-1000-8000-00805f9b34fb';
  static const String characteristicUuid =
      '0000ffd1-0000-1000-8000-00805f9b34fb';

  static const List<int> volumeUp = [0x03, 0x02, 0x01, 0x00];
  static const List<int> volumeDown = [0x03, 0x02, 0xFF, 0x00];
  static const List<int> playPause = [0x03, 0x01, 0x01];
  static const List<int> nextTrack = [0x03, 0x01, 0x02];
  static const List<int> inputSwitch = [0x04, 0x01, 0x01];

  static const String defaultDeviceHint = 'Z407';
}
