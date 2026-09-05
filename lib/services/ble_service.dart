import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';


class BleService {
  BleService._();

  static final BleService instance = BleService._();

  static const String deviceName = 'TravelBuddy';

  static final Guid serviceUuid =
      Guid('12345678-1234-1234-1234-123456789abc');

  static final Guid characteristicUuid =
      Guid('12345678-1234-1234-1234-123456789def');

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _motionCharacteristic;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notificationSubscription;

  final StreamController<int> _motionController =
      StreamController<int>.broadcast();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<int> get motionStream => _motionController.stream;

  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _connectedDevice != null;

  /// Request required Android permissions.
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    return statuses.values.every(
      (status) =>
          status.isGranted ||
          status.isLimited ||
          status.isRestricted,
    );
  }

  /// Scan and connect to the TravelBuddy ESP32.
  Future<bool> connectToTravelBuddy() async {
    try {
      final permissionsGranted = await requestPermissions();

      if (!permissionsGranted) {
        return false;
      }

      final adapterState = await FlutterBluePlus.adapterState.first;

      if (adapterState != BluetoothAdapterState.on) {
        return false;
      }

      await disconnect();

      final completer = Completer<BluetoothDevice?>();

      _scanSubscription =
    FlutterBluePlus.scanResults.listen((results) {
  for (final result in results) {
    final name = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : result.advertisementData.advName;

    debugPrint(
      'BLE FOUND -> Name: "$name" | ID: ${result.device.remoteId}',
    );

    if (name == deviceName && !completer.isCompleted) {
      debugPrint('TRAVELBUDDY FOUND!');
      completer.complete(result.device);
    }
  }
});

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
      );

      BluetoothDevice? device;

      try {
        device = await completer.future.timeout(
          const Duration(seconds: 10),
        );
      } catch (_) {
        device = null;
      }

      await FlutterBluePlus.stopScan();

      await _scanSubscription?.cancel();
      _scanSubscription = null;

      if (device == null) {
        return false;
      }

      await device.connect(
        timeout: const Duration(seconds: 15),
      );

      _connectedDevice = device;

      final services = await device.discoverServices();

      for (final service in services) {
        if (service.uuid == serviceUuid) {
          for (final characteristic in service.characteristics) {
            if (characteristic.uuid == characteristicUuid) {
              _motionCharacteristic = characteristic;
              break;
            }
          }
        }

        if (_motionCharacteristic != null) {
          break;
        }
      }

      if (_motionCharacteristic == null) {
        await disconnect();
        return false;
      }

      await _motionCharacteristic!.setNotifyValue(true);

      _notificationSubscription =
          _motionCharacteristic!.lastValueStream.listen((data) {
        if (data.isNotEmpty) {
          _motionController.add(data.first);
        }
      });

      _connectionController.add(true);

      return true;
    } catch (_) {
      await disconnect();
      return false;
    }
  }

  /// Disconnect from ESP32.
  Future<void> disconnect() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
    }

    _connectedDevice = null;
    _motionCharacteristic = null;

    _connectionController.add(false);
  }
  
  void dispose() {
    _scanSubscription?.cancel();
    _notificationSubscription?.cancel();
    _motionController.close();
    _connectionController.close();
  }
}