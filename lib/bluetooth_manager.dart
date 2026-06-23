import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'constants.dart';

class BluetoothManager {
  final FlutterBluePlus _ble = FlutterBluePlus.instance;
  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlChar;

  StreamSubscription? _scanSub;

  Future<void> startScan({Duration timeout = const Duration(seconds: 5)}) async {
    _scanSub?.cancel();
    _scanSub = _ble.scan(
      timeout: timeout,
      withServices: [Guid(LogiConstants.serviceUuid)],
    ).listen((scanResult) async {
      final device = scanResult.device;
      _device = device;
      await _scanSub?.cancel();
      await _connect(device);
    });
  }

  Future<void> _connect(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
    } catch (e) {
      // ignore if already connected
    }

    // Try to discover services; if discovery fails, we will attempt a blind write later
    List<BluetoothService> services = [];
    try {
      services = await device.discoverServices();
    } catch (e) {
      // discovery may fail on some platforms while A2DP active
    }

    for (var s in services) {
      if (s.uuid.toString().toLowerCase() == LogiConstants.serviceUuid) {
        for (var c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == LogiConstants.characteristicUuid) {
            _controlChar = c;
            break;
          }
        }
      }
    }
  }

  Future<void> sendZ407Command(List<int> bytes) async {
    if (_controlChar != null) {
      try {
        await _controlChar!.write(bytes, withoutResponse: true);
      } catch (e) {
        print('Failed to send BLE command to Z407: $e');
      }
      return;
    }

    // Blind write fallback: try writing to the characteristic by fetching it directly
    if (_device == null) return;

    try {
      final services = await _device!.discoverServices();
      for (var s in services) {
        for (var c in s.characteristics) {
          if (c.uuid.toString().toLowerCase() == LogiConstants.characteristicUuid) {
            _controlChar = c;
            await _controlChar!.write(bytes, withoutResponse: true);
            return;
          }
        }
      }
    } catch (e) {
      print('Blind write failed: $e');
    }
  }

  Future<void> disconnect() async {
    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }
  }
}
