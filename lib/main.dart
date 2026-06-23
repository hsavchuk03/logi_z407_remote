import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'bluetooth_manager.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Logi Z407 Remote',
      home: ChangeNotifierProvider(
        create: (_) => _UIModel(),
        child: const HomePage(),
      ),
    );
  }
}

class _UIModel extends ChangeNotifier {
  final BluetoothManager ble = BluetoothManager();
  double volume = 0.5;
  Timer? _debounce;

  _UIModel() {
    ble.startScan();
  }

  void setVolume(double v) {
    volume = v;
    notifyListeners();

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      final step = ((v - 0.5) * 100).round();
      final bytes = step >= 0
          ? [0x03, 0x02, 0x01, 0x00]
          : [0x03, 0x02, 0xFF, 0x00];
      ble.sendZ407Command(bytes);
    });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<_UIModel>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Logi Z407 Remote')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Volume'),
            Slider(
              value: model.volume,
              onChanged: model.setVolume,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => model.ble.sendZ407Command([0x03, 0x01, 0x01]),
              child: const Text('Play/Pause'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => model.ble.sendZ407Command([0x03, 0x01, 0x02]),
              child: const Text('Next Track'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => model.ble.sendZ407Command([0x04, 0x01, 0x01]),
              child: const Text('Input Switch (Long)'),
            ),
          ],
        ),
      ),
    );
  }
}
