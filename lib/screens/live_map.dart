import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

class LiveMap extends StatefulWidget {
  const LiveMap({super.key});

  @override
  State<LiveMap> createState() => _LiveMapState();
}

class Geofence {
  final LatLng center;
  final double radius; // in meters
  final String name;
  final Color color;

  Geofence({
    required this.center,
    required this.radius,
    required this.name,
    this.color = Colors.blue,
  });
}

// ✅ Implement WidgetsBindingObserver
class _LiveMapState extends State<LiveMap> with WidgetsBindingObserver {
  LatLng _currentPosition = const LatLng(28.6139, 77.2090); // Default Delhi
  Timer? _timer;
  final MapController _mapController = MapController();
  bool _hasPermission = false;
  bool _isLocationServiceEnabled = false;
  String _statusMessage = "Initializing...";

  // Hardcoded geofences
  final List<Geofence> _geofences = [
    Geofence(
      center: const LatLng(28.6139, 77.2090), // Delhi coordinates
      radius: 500, // 500 meters radius
      name: "Delhi Central Zone",
      color: Colors.blue.withOpacity(0.3),
    ),
    Geofence(
      center: const LatLng(28.7041, 77.1025), // Another location in Delhi
      radius: 300, // 300 meters radius
      name: "North Delhi Zone",
      color: Colors.red.withOpacity(0.3),
    ),
    Geofence(
      center: const LatLng(28.463093, 77.490384),
      radius: 100, // 100 meters radius
      name: "NIET",
      color: Colors.green.withOpacity(0.3),
    ),
    Geofence(
      center: const LatLng(28.43752, 77.44666),
      radius: 500, // 100 meters radius
      name: "Flodded River",
      color: Colors.red.withOpacity(0.5),
    ),

  ];

  String _geofenceStatus = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initLocationFlow();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel(); // cancel timer safely
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatus();
    }
  }

  Future<void> _checkPermissionStatus() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      setState(() {
        _hasPermission = true;
        _statusMessage = "Permission granted";
      });
      _startLocationUpdates();
    }
  }

  Future<void> _initLocationFlow() async {
    setState(() => _statusMessage = "Checking location services...");

    // 1) Check location services
    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isLocationServiceEnabled) {
      setState(() => _statusMessage = "Location services disabled");
      return;
    }

    // 2) Request permissions
    await _requestLocationPermissions();

    if (!_hasPermission) {
      setState(() => _statusMessage = "Location permission denied");
      return;
    }

    // 3) Start location updates
    await _startLocationUpdates();
  }

  Future<void> _requestLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _hasPermission = false;
          _statusMessage = "Location permission denied";
        });
        return;
      }
    }

    _isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!_isLocationServiceEnabled) {
      setState(() => _statusMessage = "Location services disabled");
      return;
    }

    setState(() {
      _hasPermission = true;
      _statusMessage = "Permission granted";
    });
  }

  Future<void> _startLocationUpdates() async {
    setState(() => _statusMessage = "Getting location...");

    try {
      await _updateLocation(moveMap: true);

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        _updateLocation(moveMap: false);
      });

      setState(() => _statusMessage = "Tracking location");
    } catch (e) {
      setState(() => _statusMessage = "Error getting location: $e");
    }
  }

  Future<void> _updateLocation({bool moveMap = false}) async {
    if (!_hasPermission || !_isLocationServiceEnabled) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final target = LatLng(position.latitude, position.longitude);

      final d = const Distance();
      final meters = d.as(LengthUnit.Meter, _currentPosition, target);
      final movedEnough = meters > 1.0;

      if (movedEnough || moveMap) {
        setState(() => _currentPosition = target);

        // Check if inside any geofence
        _checkGeofences(target);

        if (moveMap) {
          _mapController.move(target, 18.0);
        }
      }
    } catch (e) {
      setState(() => _statusMessage = "Location error: $e");
    }
  }

  void _checkGeofences(LatLng position) {
    final d = const Distance();
    bool insideAnyGeofence = false;
    String insideGeofenceName = "";

    for (final geofence in _geofences) {
      final distance = d(position, geofence.center);

      if (distance <= geofence.radius) {
        insideAnyGeofence = true;
        insideGeofenceName = geofence.name;
        break;
      }
    }

    setState(() {
      if (insideAnyGeofence) {
        _geofenceStatus = "Inside $insideGeofenceName";
      } else {
        _geofenceStatus = "Not inside any geofence";
      }
    });
  }

  Future<void> _centerOnMe() async {
    if (!_hasPermission) {
      await _initLocationFlow();
      return;
    }

    if (!_isLocationServiceEnabled) {
      setState(() => _statusMessage = "Enable location services first");
      return;
    }

    try {
      // ✅ Get cached location instantly
      final cachedPos = await Geolocator.getLastKnownPosition();

      if (cachedPos != null) {
        final target = LatLng(cachedPos.latitude, cachedPos.longitude);
        setState(() {
          _currentPosition = target;
          _statusMessage = "Centered instantly (cached)";
        });
        _mapController.move(target, 18.0);
      }

      // ✅ Also fetch fresh GPS in background (but don't block UI)
      Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).then((freshPos) {
        final target = LatLng(freshPos.latitude, freshPos.longitude);
        setState(() {
          _currentPosition = target;
          _statusMessage = "Updated with fresh location";
        });
        _mapController.move(target, 18.0);
      });
    } catch (e) {
      setState(() => _statusMessage = "Error getting location: $e");
    }
  }

  Future<void> _shareLocationWhatsApp() async {
    if (!_hasPermission) {
      setState(() => _statusMessage = "Need location permission to share");
      return;
    }

    final lat = _currentPosition.latitude;
    final lng = _currentPosition.longitude;
    final mapsUrl = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    final text = Uri.encodeComponent('My location: $mapsUrl');

    // ✅ Use wa.me link
    final waUrl = "https://wa.me/?text=$text";

    if (await canLaunchUrlString(waUrl)) {
      await launchUrlString(
        waUrl,
        mode: LaunchMode.externalApplication,
      );
    } else {
      setState(() => _statusMessage = "WhatsApp not installed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.grey,
              border: Border.all(color: Colors.white10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _hasPermission && _isLocationServiceEnabled
                  ? FlutterMap(
                mapController: _mapController,
                options: MapOptions(center: _currentPosition, zoom: 15),
                children: [
                  TileLayer(
  urlTemplate:
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
  userAgentPackageName: 'com.example.safe_yatra',
),

                  // Draw geofence circles
                  CircleLayer(
                    circles: _geofences.map((geofence) {
                      return CircleMarker(
                        point: geofence.center,
                        color: geofence.color,
                        borderColor: geofence.color.withOpacity(0.8),
                        borderStrokeWidth: 2,
                        useRadiusInMeter: true,
                        radius: geofence.radius,
                      );
                    }).toList(),
                  ),

                  // Add markers for geofence centers
                  MarkerLayer(
                    markers: [
                      // Current position marker
                      Marker(
                        point: _currentPosition,
                        width: 50,
                        height: 50,
                        child: const Icon(
                          Icons.person_pin_circle,
                          color: Colors.redAccent,
                          size: 40,
                        ),
                      ),

                      // Geofence center markers
                      ..._geofences.map((geofence) {
                        return Marker(
                          point: geofence.center,
                          width: 30,
                          height: 30,
                          child: Icon(
                            Icons.location_pin,
                            color: geofence.color,
                            size: 30,
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_disabled,
                        size: 40, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _statusMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _initLocationFlow,
                      child: const Text("Enable Location"),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top-left: geofence status
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _geofenceStatus,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),

          // Right-bottom: center-on-me
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              onPressed: _centerOnMe,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          // Left-bottom: share to WhatsApp
          Positioned(
            left: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'share_whatsapp',
              onPressed: _shareLocationWhatsApp,
              backgroundColor: Colors.white,
              child: FaIcon(
  FontAwesomeIcons.whatsapp,
  color: Colors.green,
),
              tooltip: 'Share via WhatsApp',
            ),
          ),
        ],
      ),
    );
  }
}