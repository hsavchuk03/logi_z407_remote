import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'constants.dart';

enum BleConnectionStatus { scanning, connecting, connected, disconnected, error }

class BluetoothManager extends ChangeNotifier {
  BluetoothManager({String targetDeviceHint = LogiConstants.defaultDeviceHint})
      : _targetDeviceHint = targetDeviceHint;

  final String _targetDeviceHint;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _controlChar;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  final Queue<List<int>> _pendingWrites = Queue<List<int>>();
  bool _isProcessingQueue = false;

  BleConnectionStatus _status = BleConnectionStatus.disconnected;
  String _statusMessage = 'Disconnected';
  String? _deviceName;

  BleConnectionStatus get status => _status;
  String get statusMessage => _statusMessage;
  String? get deviceName => _deviceName;

  Future<void> startScan({Duration timeout = const Duration(seconds: 8)}) async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _setStatus(BleConnectionStatus.scanning, 'Scanning for Z407…');

    try {
      await FlutterBluePlus.stopScan();
      await FlutterBluePlus.startScan(
        withServices: [Guid(LogiConstants.serviceUuid)],
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen(
        (results) async {
          for (final result in results) {
            final device = result.device;
            final label = device.platformName.isNotEmpty ? device.platformName : 'Unknown';
            final matchesHint =
                label.toLowerCase().contains(_targetDeviceHint.toLowerCase()) ||
                label.toLowerCase().contains('z407');

            if (matchesHint) {
              _device = device;
              _deviceName = label;
              _setStatus(BleConnectionStatus.connecting, 'Connecting to $label');
              await _scanSubscription?.cancel();
              _scanSubscription = null;
              unawaited(connectToDevice(device));
              return;
            }
          }
        },
        onError: (_) {
          _setStatus(BleConnectionStatus.error, 'Scan failed');
        },
      );
    } catch (_) {
      _setStatus(BleConnectionStatus.error, 'Scan failed');
    }
  }

  Future<void> connectToDevice([BluetoothDevice? device]) async {
    final target = device ?? _device;
    if (target == null) {
      _setStatus(BleConnectionStatus.disconnected, 'No device available');
      return;
    }

    try {
      await target.connect(autoConnect: false);
      _device = target;
      _deviceName = target.platformName.isNotEmpty ? target.platformName : _deviceName;
      _setStatus(BleConnectionStatus.connected, 'Connected to $_deviceName');
      await _discoverControlCharacteristic();
    } catch (e) {
      _setStatus(BleConnectionStatus.error, 'Connection failed: $e');
    }
  }

  Future<void> _discoverControlCharacteristic() async {
    if (_device == null) {
      return;
    }

    try {
      final services = await _device!.discoverServices();
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == LogiConstants.serviceUuid.toLowerCase()) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toLowerCase() ==
                LogiConstants.characteristicUuid.toLowerCase()) {
              _controlChar = characteristic;
              return;
            }
          }
        }
      }
      _controlChar = null;
    } catch (_) {
      _controlChar = null;
    }
  }

  Future<void> sendCommand(List<int> payload) async {
    _pendingWrites.add(List<int>.from(payload));
    if (_isProcessingQueue) {
      return;
    }

    _isProcessingQueue = true;
    try {
      while (_pendingWrites.isNotEmpty) {
        final nextPayload = _pendingWrites.removeFirst();
        await _writePayload(nextPayload);
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  Future<void> _writePayload(List<int> payload) async {
    if (_device == null) {
      await connectToDevice();
      return;
    }

    final connectionState = await _device!.connectionState.first;
    if (connectionState != BluetoothConnectionState.connected) {
      await connectToDevice();
    }

    if (_device == null) {
      _setStatus(BleConnectionStatus.disconnected, 'Device unavailable');
      return;
    }

    try {
      await _ensureCharacteristic();
      if (_controlChar != null) {
        await _controlChar!.write(payload, withoutResponse: true);
        return;
      }

      final services = await _device!.discoverServices();
      for (final service in services) {
        for (final characteristic in service.characteristics) {
          if (characteristic.uuid.toString().toLowerCase() ==
              LogiConstants.characteristicUuid.toLowerCase()) {
            _controlChar = characteristic;
            await _controlChar!.write(payload, withoutResponse: true);
            return;
          }
        }
      }

      _setStatus(BleConnectionStatus.error, 'Target characteristic unavailable');
    } catch (e) {
      _setStatus(BleConnectionStatus.error, 'Write failed: $e');
      debugPrint('BLE write failed: $e');
    }
  }

  Future<void> _ensureCharacteristic() async {
    if (_controlChar != null) {
      return;
    }
    await _discoverControlCharacteristic();
  }

  Future<void> disconnect() async {
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();

    if (_device != null) {
      try {
        await _device!.disconnect();
      } catch (_) {}
    }

    _device = null;
    _controlChar = null;
    _setStatus(BleConnectionStatus.disconnected, 'Disconnected');
  }

  void _setStatus(BleConnectionStatus status, String message) {
    _status = status;
    _statusMessage = message;
    notifyListeners();
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }
}
