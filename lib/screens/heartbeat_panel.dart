import 'dart:async';

import 'package:flutter/material.dart';

import '../services/ble_service.dart';

class HeartbeatPanel extends StatefulWidget {
  const HeartbeatPanel({super.key});

  @override
  State<HeartbeatPanel> createState() => _HeartbeatPanelState();
}

class _HeartbeatPanelState extends State<HeartbeatPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  final BleService _bleService = BleService.instance;

  StreamSubscription<int>? _motionSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  bool _crashDetected = false;

  int _value = 0;
  String _status = "Disconnected";
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    // Heartbeat animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.94,
          end: 1.08,
        ).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.08,
          end: 0.96,
        ).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.96,
          end: 1.06,
        ).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.06,
          end: 0.94,
        ).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 25,
      ),
    ]).animate(_controller);

    _listenToBle();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectToTravelBuddy();
    });
  }

  void _listenToBle() {
    // Receive MPU6050 motion values
    _motionSubscription =
        _bleService.motionStream.listen((motionValue) {
      if (!mounted) return;

      setState(() {
        _value = motionValue;
      });
    });

    // Listen to connection state
    _connectionSubscription =
        _bleService.connectionStream.listen((connected) {
      if (!mounted) return;

      setState(() {
        _isConnected = connected;

        if (connected) {
          _status = "Connected to TravelBuddy";
        } else {
          _status = "Disconnected";
        }
      });
    });
  }

  Future<void> _connectToTravelBuddy() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _status = "Scanning for TravelBuddy...";
    });

    final connected =
        await _bleService.connectToTravelBuddy();

    if (!mounted) return;

    setState(() {
      _isConnecting = false;

      if (connected) {
        _status = "Connected to TravelBuddy";
      } else {
        _status = "TravelBuddy not found";
      }
    });
  }

  Future<void> _reconnect() async {
    setState(() {
      _status = "Reconnecting...";
      _value = 0;
    });

    await _bleService.disconnect();

    if (!mounted) return;

    await Future.delayed(
      const Duration(milliseconds: 500),
    );

    await _connectToTravelBuddy();
  }

  @override
  void dispose() {
    _motionSubscription?.cancel();
    _connectionSubscription?.cancel();

    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: _crashDetected
                ? Colors.red.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: _crashDetected
                  ? Colors.red
                  : Colors.white12,
              width: _crashDetected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _crashDetected
                  ? [
                      Colors.red.withValues(alpha: 0.15),
                      Colors.orange.withValues(alpha: 0.1),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
            ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_crashDetected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning,
                        color: Colors.red[100],
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CRASH DETECTED',
                        style: TextStyle(
                          color: Colors.red[100],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              if (_crashDetected)
                const SizedBox(height: 10),

              ScaleTransition(
                scale: _scale,
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _crashDetected
                            ? Colors.red.withValues(alpha: 0.5)
                            : Colors.tealAccent.withValues(alpha: 0.35),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _crashDetected
                        ? Icons.warning
                        : Icons.favorite,
                    color: _crashDetected
                        ? Colors.red
                        : _isConnected
                            ? Colors.tealAccent.shade400
                            : Colors.grey,
                    size: 68,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                _crashDetected
                    ? 'CRASH ALERT!'
                    : 'Motion Monitor',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _crashDetected
                      ? Colors.red
                      : const Color.fromARGB(
                          255,
                          231,
                          7,
                          7,
                        ),
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _isConnected
                      ? Colors.green
                      : Colors.grey,
                  fontSize: 13.5,
                ),
              ),

              const SizedBox(height: 18),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _crashDetected
                        ? Colors.red
                        : Colors.white10,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors,
                      color: _crashDetected
                          ? Colors.red
                          : _isConnected
                              ? Colors.tealAccent.shade400
                              : Colors.grey,
                      size: 22,
                    ),

                    const SizedBox(width: 8),

                    Text(
                      '$_value',
                      style: TextStyle(
                        color: _crashDetected
                            ? Colors.red
                            : _isConnected
                                ? Colors.tealAccent.shade400
                                : Colors.grey,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (!_isConnected)
                ElevatedButton(
                  onPressed: _isConnecting
                      ? null
                      : _reconnect,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.tealAccent.shade400,
                    foregroundColor: Colors.black,
                  ),
                  child: Text(
                    _isConnecting
                        ? 'Connecting...'
                        : 'Reconnect',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}