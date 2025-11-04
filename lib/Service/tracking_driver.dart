import 'package:e_service/Beli/shop.dart';
import 'package:e_service/Home/Home.dart';
import 'package:e_service/Others/notifikasi.dart';
import 'package:e_service/Profile/profile.dart';
import 'package:e_service/Promo/promo.dart';
import 'package:e_service/Service/Service.dart';
import 'package:e_service/Service/detail_service_midtrans.dart';
import 'package:e_service/api_services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math.dart' as vector_math;

const String mapStoreName = 'e_service_map_store';

// Custom Tween for LatLng animation
class LatLngTween extends Tween<LatLng> {
  LatLngTween({required LatLng begin, required LatLng end}) : super(begin: begin, end: end);

  @override
  LatLng lerp(double t) {
    final lat = begin!.latitude + (end!.latitude - begin!.latitude) * t;
    final lng = begin!.longitude + (end!.longitude - begin!.longitude) * t;
    return LatLng(lat, lng);
  }
}

class TrackingPage extends StatefulWidget {
  final String? queueCode; // trans_kode

  const TrackingPage({super.key, this.queueCode});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> with TickerProviderStateMixin {
  int currentIndex = 0;

  // Map
  LatLng? _userLocation;
  LatLng? _driverLocation; // Start as null, will be set from database
  final ValueNotifier<LatLng?> _driverLocationNotifier = ValueNotifier(null); // For real-time marker updates
  LatLng? _previousDriverLocation;
  List<LatLng> _routePoints = [];
  final mapController = MapController();
  String _driverIcon = 'motorcycle'; // Default icon
  bool _isMapReady = false;
  bool _hasFittedBounds = false;
  bool _userHasInteracted = false;

  // Animation
  AnimationController? _animationController;
  Animation<LatLng>? _driverAnimation;

  Timer? _locationPollingTimer;
  Timer? _statusPollingTimer;
  int _locationPollingRetryCount = 0;
  static const int _maxLocationRetries = 3;

  // Timeline state
  List<_TimelineItem> _timeline = [];
  bool _isTimelineExpanded = false;
  String _currentStatus = 'waiting';
  DateTime? _createdAt;
  DateTime? _updatedAt;

  static const _collapsedCount = 7;

  @override
  void initState() {
    super.initState();
    _loadOrderAddress();
    _refreshStatus(); // initial fetch
    _startStatusPolling();
  }

  @override
  void dispose() {
    _stopLocationPolling(); // Ensure polling stops when page is closed
    _statusPollingTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  // ========================= Polling =========================

  void _startLocationPolling() {
    _locationPollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      // Stop polling if transaction is completed or cancelled
      if (_shouldStopPolling()) {
        _stopLocationPolling();
        return;
      }

      if (widget.queueCode == null || widget.queueCode!.isEmpty) return;

      try {
        final locationData = await ApiService.getDriverLocation(widget.queueCode!);
        if (locationData != null &&
            locationData['latitude'] != null &&
            locationData['longitude'] != null) {
          final newLat = double.tryParse(locationData['latitude'].toString());
          final newLng = double.tryParse(locationData['longitude'].toString());
          final icon = locationData['icon'] ?? 'motorcycle'; // Get icon from API, default to 'motorcycle'
          if (newLat != null && newLng != null) {
            final newLocation = LatLng(newLat, newLng);
            if (_driverLocation != newLocation) {
              print('📍 [TRACKING] Driver location changed from ${_driverLocation?.latitude ?? "null"},${_driverLocation?.longitude ?? "null"} to ${newLocation.latitude},${newLocation.longitude}');
              _previousDriverLocation = _driverLocation;
              _startDriverAnimation(newLocation);
              // Center map on new driver location only if map is ready and user hasn't interacted
              if (_isMapReady && !_userHasInteracted) {
                mapController.move(newLocation, 13);
              }
            }
            setState(() {
              _driverIcon = icon;
              _driverLocation = newLocation;
              _driverLocationNotifier.value = newLocation;
            });
            if (_userLocation != null) await _getPolylineRoute();
            // Fit bounds when driver location changes
            _fitBoundsToRoute();
            _locationPollingRetryCount = 0; // Reset retry count on success
          }
        } else {
          _handleLocationPollingError('Invalid location data received: $locationData');
        }
      } catch (e) {
        _handleLocationPollingError('API Error: $e');
      }
    });
  }

  void _stopLocationPolling() {
    _locationPollingTimer?.cancel();
    _locationPollingTimer = null;
    print('📍 Location polling stopped for queueCode: ${widget.queueCode}');
  }

  bool _shouldStopPolling() {
    // Stop polling for completed, cancelled, or other final statuses
    final stopStatuses = ['completed', 'cancelled', 'cancel', 'failed', 'rejected'];
    return stopStatuses.contains(_currentStatus.toLowerCase());
  }

  void _handleLocationPollingError(String error) {
    _locationPollingRetryCount++;
    print('❌ Location polling error (attempt $_locationPollingRetryCount/$_maxLocationRetries): $error');

    if (_locationPollingRetryCount >= _maxLocationRetries) {
      print('🚫 Max retries reached, stopping location polling');
      _stopLocationPolling();
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      await _refreshStatus();
    });
  }

  // Ambil trans_status dari transaksi
  Future<void> _refreshStatus() async {
    if (widget.queueCode == null || widget.queueCode!.isEmpty) return;
    try {
      final detail = await ApiService.getOrderDetail(widget.queueCode!);
      if (detail == null) return;

      // Normalisasi status ke lowercase + handle alias
      String status = (detail['trans_status'] ?? 'waiting').toString().toLowerCase().trim();
      status = _normalizeStatus(status);

      // Ambil waktu dari backend jika ada
      final createdAtStr = (detail['created_at'] ?? detail['trans_tgl'] ?? detail['createdAt'])?.toString();
      final updatedAtStr = (detail['updated_at'] ?? detail['updatedAt'] ?? createdAtStr)?.toString();
      final createdAt = DateTime.tryParse(createdAtStr ?? '');
      final updatedAt = DateTime.tryParse(updatedAtStr ?? '');

      setState(() {
        _currentStatus = status;
        _createdAt = createdAt ?? DateTime.now().subtract(const Duration(hours: 2));
        _updatedAt = updatedAt ?? DateTime.now();
        _timeline = _buildTimelineFromCurrentStatus(_currentStatus, _createdAt!, _updatedAt!);
      });

      // Start/stop location polling based on status
      _updateLocationPollingForStatus(status);
    } catch (e) {
      // ignore
    }
  }

  void _updateLocationPollingForStatus(String status) {
    // Start polling when technician is active (enroute or later)
    final activeStatuses = ['enroute', 'arrived', 'waitingapproval', 'pickingparts', 'repairing'];
    final shouldPoll = activeStatuses.contains(status.toLowerCase());

    if (shouldPoll && _locationPollingTimer == null) {
      print('📍 Starting location polling for active status: $status');
      _startLocationPolling();
    } else if (!shouldPoll && _locationPollingTimer != null) {
      print('📍 Stopping location polling for inactive status: $status');
      _stopLocationPolling();
    } else if (shouldPoll && _locationPollingTimer != null) {
      // If already polling for active status, ensure it's the correct transaction
      print('📍 Location polling already active for status: $status');
    }
  }

  // ========================= Lokasi user & rute =========================

  Future<void> _loadOrderAddress() async {
    if (widget.queueCode == null || widget.queueCode!.isEmpty) {
      // If no queueCode, don't set any location
      return;
    }
    try {
      final detail = await ApiService.getOrderDetail(widget.queueCode!);
      if (detail != null) {
        print('📍 [LOAD_ADDRESS] Order detail received: $detail');

        // Try different field names for latitude/longitude first
        final latValue = detail['latitude'] ?? detail['lat'];
        final lngValue = detail['longitude'] ?? detail['lng'];
        print('📍 [LOAD_ADDRESS] Lat/Lng values: lat=$latValue, lng=$lngValue');

        if (latValue != null && lngValue != null) {
          final lat = double.tryParse(latValue.toString());
          final lng = double.tryParse(lngValue.toString());
          if (lat != null && lng != null) {
            setState(() {
              _userLocation = LatLng(lat, lng);
            });
            print('📍 [LOAD_ADDRESS] Set user location from coordinates: $lat, $lng');
            await _getPolylineRoute();
            return;
          } else {
            print('📍 [LOAD_ADDRESS] Failed to parse coordinates: lat=$lat, lng=$lng');
          }
        }

        // If no coordinates, try to geocode the address
        final address = detail['alamat'] ?? detail['address'] ?? detail['location'];
        final trimmedAddress = address?.toString().trim();
        print('📍 [LOAD_ADDRESS] Address for geocoding: "$trimmedAddress"');
        print('📍 [LOAD_ADDRESS] Address is null: ${trimmedAddress == null}, isEmpty: ${trimmedAddress?.isEmpty}');
        if (trimmedAddress != null && trimmedAddress.isNotEmpty) {
          print('📍 [LOAD_ADDRESS] Calling geocode function...');
          await _geocodeAddress(trimmedAddress);
        } else {
          print('📍 [LOAD_ADDRESS] No address available for geocoding');
        }
      } else {
        print('📍 [LOAD_ADDRESS] No order detail received');
      }
    } catch (e) {
      print('❌ [LOAD_ADDRESS] Error loading order address: $e');
    }
  }

  Future<void> _geocodeAddress(String address) async {
    print('🔍 [GEOCODING] Starting geocoding for address: "$address"');
    try {
      // First try full address
      List<geocoding.Location> locations = await geocoding.locationFromAddress(address);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _userLocation = latLng;
        });
        await _getPolylineRoute();
        print('✅ [GEOCODING] Successfully geocoded full address "$address" to coordinates: ${loc.latitude}, ${loc.longitude}');
        return;
      }
    } catch (e) {
      print('⚠️ [GEOCODING] Full address geocoding failed: $e');
    }

    // Fallback: try simplified address (remove house number and specific details)
    try {
      final simplifiedAddress = _simplifyAddress(address);
      print('🔄 [GEOCODING] Trying simplified address: "$simplifiedAddress"');
      List<geocoding.Location> locations = await geocoding.locationFromAddress(simplifiedAddress);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final latLng = LatLng(loc.latitude, loc.longitude);
        setState(() {
          _userLocation = latLng;
        });
        await _getPolylineRoute();
        print('✅ [GEOCODING] Successfully geocoded simplified address "$simplifiedAddress" to coordinates: ${loc.latitude}, ${loc.longitude}');
        return;
      }
    } catch (e) {
      print('⚠️ [GEOCODING] Simplified address geocoding failed: $e');
    }

    // Final fallback: use Jakarta coordinates as default
    print('❌ [GEOCODING] All geocoding attempts failed, using Jakarta as fallback');
    const fallbackLatLng = LatLng(-6.2088, 106.8456); // Jakarta coordinates
    setState(() {
      _userLocation = fallbackLatLng;
    });
    await _getPolylineRoute();
    print('🗺️ [GEOCODING] Set fallback location: $fallbackLatLng');
  }

  String _simplifyAddress(String address) {
    // Remove house numbers, specific building names, etc.
    // Keep main street, district, city, province
    final parts = address.split(',').map((s) => s.trim()).toList();
    if (parts.length >= 2) {
      // Remove first part if it looks like a house number/street number
      if (parts[0].contains('No.') || parts[0].contains('Jl.') && parts[0].split(' ').length <= 3) {
        parts.removeAt(0);
      }
      return parts.join(', ');
    }
    return address;
  }

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _userLocation = LatLng(position.latitude, position.longitude);
    });

    await _getPolylineRoute();
  }

  Future<void> _getPolylineRoute() async {
    if (_userLocation == null || _driverLocation == null) return;
    final url =
        'https://router.project-osrm.org/route/v1/driving/${_driverLocation!.longitude},${_driverLocation!.latitude};${_userLocation!.longitude},${_userLocation!.latitude}?geometries=geojson';

    try {
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);
      final coords = (data['routes'][0]['geometry']['coordinates'] as List<dynamic>);
      setState(() {
        _routePoints = coords
            .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
            .toList();
      });
      // Fit bounds after route is fetched
      _fitBoundsToRoute();
    } catch (e) {
      debugPrint("Gagal ambil rute: $e");
    }
  }

  void _fitBoundsToRoute() {
    // Don't fit bounds if user has interacted with the map
    if (_userHasInteracted) return;

    if (_routePoints.isEmpty && _userLocation == null && _driverLocation == null) return;

    List<LatLng> points = [];
    if (_routePoints.isNotEmpty) {
      points.addAll(_routePoints);
    }
    if (_userLocation != null) {
      points.add(_userLocation!);
    }
    if (_driverLocation != null) {
      points.add(_driverLocation!);
    }

    if (points.isEmpty) return;

    double minLat = points.map((p) => p.latitude).reduce((a, b) => a < b ? a : b);
    double maxLat = points.map((p) => p.latitude).reduce((a, b) => a > b ? a : b);
    double minLng = points.map((p) => p.longitude).reduce((a, b) => a < b ? a : b);
    double maxLng = points.map((p) => p.longitude).reduce((a, b) => a > b ? a : b);

    LatLngBounds bounds = LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));

    // Fit bounds with padding
    mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: EdgeInsets.all(50)));
  }

  void _startDriverAnimation(LatLng newLocation) {
    _animationController?.dispose();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _driverAnimation = LatLngTween(
      begin: _previousDriverLocation ?? _driverLocation ?? newLocation,
      end: newLocation,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    _driverAnimation!.addListener(() {
      setState(() {
        _driverLocation = _driverAnimation!.value;
      });
    });

    _animationController!.forward();
  }

  // ========================= Timeline builder =========================

  // Urutan status (lowercase) – harus konsisten dengan yang dikirim teknisi
  final List<String> _orderedStatuses = const [
    'waiting',
    'accepted',
    'enroute',
    'arrived',
    'waitingapproval',
    'pickingparts',
    'repairing',
    'completed',
  ];

  String _normalizeStatus(String s) {
    final ss = s.replaceAll(' ', '').replaceAll('_', '');
    switch (ss) {
      case 'pending':
        return 'waiting';
      case 'enroute':
      case 'enrute':
      case 'enrouted':
      case 'en_route':
        return 'enroute';
      case 'waitingapproval':
      case 'waitingapprovalstatus':
        return 'waitingapproval';
      case 'pickingparts':
      case 'pickingpart':
      case 'picking_parts':
        return 'pickingparts';
      default:
        return ss;
    }
  }

  _StatusMeta _statusMeta(String statusKey) {
    switch (statusKey.toLowerCase()) {
      case 'waiting':
        return _StatusMeta('Pesanan Dibuat', 'Pesanan dibuat dan menunggu konfirmasi teknisi.');
      case 'accepted':
        return _StatusMeta('Teknisi Ditugaskan', 'Teknisi sudah ditugaskan. Pesanan akan diproses.');
      case 'enroute':
        return _StatusMeta('Pesanan dalam Pengiriman', 'Teknisi dalam perjalanan menuju lokasi Anda.');
      case 'arrived':
        return _StatusMeta('Sampai Lokasi', 'Teknisi telah tiba di lokasi Anda.');
      case 'waitingapproval':
        return _StatusMeta('Menunggu Persetujuan', 'Temuan kerusakan menunggu persetujuan biaya/perbaikan.');
      case 'pickingparts':
        return _StatusMeta('Persiapan Part', 'Teknisi sedang menyiapkan/mengambil part yang dibutuhkan.');
      case 'repairing':
        return _StatusMeta('Sedang Dikerjakan', 'Perbaikan perangkat Anda sedang diproses.');
      case 'completed':
        return _StatusMeta('Terkirim', 'Layanan selesai. Terima kasih telah menggunakan layanan kami.');
      default:
        return _StatusMeta('Status Tidak Dikenal', 'Sedang memuat informasi status.');
    }
  }

  // Distribusi waktu untuk step yang sudah terjadi (createdAt..updatedAt)
  List<DateTime?> _distributeTimes({
    required int activeIndex,
    required DateTime start,
    required DateTime end,
    required int total,
  }) {
    if (activeIndex <= 0) {
      return List.generate(total, (i) => i == 0 ? start : null);
    }
    if (!end.isAfter(start)) {
      return List.generate(total, (i) {
        if (i > activeIndex) return null;
        return start.add(Duration(minutes: 5 * i));
      });
    }
    final steps = activeIndex;
    final interval = end.difference(start) ~/ (steps);
    return List.generate(total, (i) {
      if (i > activeIndex) return null;
      return start.add(interval * i);
    });
  }

  List<_TimelineItem> _buildTimelineFromCurrentStatus(
      String currentStatus, DateTime createdAt, DateTime updatedAt) {
    final total = _orderedStatuses.length;
    final activeIndex = _orderedStatuses.indexOf(currentStatus);
    final validActiveIndex = activeIndex >= 0 ? activeIndex : 0;

    final times = _distributeTimes(
      activeIndex: validActiveIndex,
      start: createdAt,
      end: updatedAt,
      total: total,
    );

    final List<_TimelineItem> items = [];
    if (currentStatus == 'completed') {
      // All statuses are done (green) when completed
      for (int i = 0; i < total; i++) {
        final s = _orderedStatuses[i];
        final meta = _statusMeta(s);
        items.add(_TimelineItem(
          time: times[i],
          title: meta.title,
          description: meta.description,
          state: StepState.done,
        ));
      }
    } else {
      // Normal logic: done up to activeIndex, progress at activeIndex, pending after
      for (int i = 0; i < total; i++) {
        final s = _orderedStatuses[i];
        final meta = _statusMeta(s);
        final state = i < validActiveIndex
            ? StepState.done
            : (i == validActiveIndex ? StepState.progress : StepState.pending);

        items.add(_TimelineItem(
          time: times[i],
          title: meta.title,
          description: meta.description,
          state: state,
        ));
      }
    }

    // Keep order as per _orderedStatuses (vertical order)
    return items;
  }

  String _fmt(DateTime? dt) => dt == null ? '—' : DateFormat('dd-MM-yyyy HH:mm').format(dt);

  IconData _getDriverIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'truck':
        return Icons.local_shipping;
      case 'van':
        return Icons.airport_shuttle;
      case 'motorcycle':
      default:
        return Icons.motorcycle;
    }
  }

  // ========================= UI =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        title: Image.asset('assets/image/logo.png', width: 95, height: 30),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: _bottomNavBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HANYA MAP (tanpa info nama/device/dll)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildMap(),
            ),

            const SizedBox(height: 16),

            // Timeline
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Riwayat Status', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildTimelineSection(),
                  if (_currentStatus == 'completed') ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailServiceMidtransPage(
                                serviceType: 'repair', // Placeholder, adjust as needed
                                nama: 'Customer', // Placeholder, adjust as needed
                                status: _currentStatus,
                                jumlahBarang: 1,
                                items: const [], // Placeholder, adjust as needed
                                alamat: 'Alamat Customer', // Placeholder, adjust as needed
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Lanjutkan Pembayaran',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    // Show map only if status is enroute or later
    final activeStatuses = ['enroute', 'arrived', 'waitingapproval', 'pickingparts', 'repairing'];
    final shouldShowMap = activeStatuses.contains(_currentStatus.toLowerCase());

    if (!shouldShowMap) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 8),
              Text(
                'Map akan muncul saat teknisi dalam perjalanan',
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // If we have driver location but no user location, use driver location as center
    final mapCenter = _userLocation ?? _driverLocation ?? const LatLng(-6.2, 106.816666); // Default to Jakarta if nothing

    // Show loading only if we have no locations at all and are actively polling
    if (_driverLocation == null && _locationPollingTimer != null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Mark map as ready when building
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMapReady) {
        setState(() {
          _isMapReady = true;
        });
      }
    });

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom: 13,
        minZoom: 3.0,
        maxZoom: 19.0,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate, // Disable rotation
        ),
        onPositionChanged: (position, hasGesture) {
          if (hasGesture) {
            _userHasInteracted = true;
          }
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
          userAgentPackageName: 'com.azzahra.e_service',
          maxZoom: 19,
          minZoom: 3,
          keepBuffer: 2,
        ),
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(points: _routePoints, color: Colors.blueAccent, strokeWidth: 4),
            ],
          ),
        MarkerLayer(
          markers: [
            // Lokasi User (only show if available) - place at end of route if route exists
            if (_userLocation != null)
              Marker(
                point: _routePoints.isNotEmpty ? _routePoints.last : _userLocation!,
                width: 16,
                height: 16,
                child: Container(decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
              ),
            // Lokasi Driver - place at start of route if route exists
            if (_driverLocation != null)
              Marker(
                point: _routePoints.isNotEmpty ? _routePoints.first : _driverLocation!,
                width: 40,
                height: 40,
                child: Icon(_getDriverIcon(_driverIcon), color: Colors.blue, size: 28),
              ),
          ],
        ),
      ],
    );
  }

  // ========================= Timeline UI =========================

  Widget _buildTimelineSection() {
    if (_timeline.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text('Belum ada pembaruan status.', style: GoogleFonts.poppins(color: Colors.grey[700], fontSize: 13)),
      );
    }

    final items = List<_TimelineItem>.from(_timeline);
    final visibleCount = _isTimelineExpanded
        ? items.length
        : (items.length < _collapsedCount ? items.length : _collapsedCount);
    final visibleItems = items.take(visibleCount).toList();

    List<Widget> children = [];
    for (int i = 0; i < visibleItems.length; i++) {
      final e = visibleItems[i];
      final isFirst = i == 0;
      final isLast = i == visibleItems.length - 1 && visibleItems.length == items.length;

      // Add separator if transitioning from done to progress
      if (i > 0 && e.state == StepState.progress && visibleItems[i - 1].state == StepState.done) {
        children.add(Container(
          height: 1,
          color: Colors.grey.shade300,
          margin: const EdgeInsets.symmetric(vertical: 8),
        ));
      }

      children.add(_timelineRow(
        dateText: _fmt(e.time),
        title: e.title,
        description: e.description,
        state: e.state,
        showTopLine: !isFirst,
        showBottomLine: !isLast,
      ));
    }

    if (items.length > _collapsedCount) {
      children.add(Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => setState(() => _isTimelineExpanded = !_isTimelineExpanded),
          child: Text(
            _isTimelineExpanded ? 'Tampilkan Lebih Sedikit' : 'Tampilkan Lebih Banyak',
            style: GoogleFonts.poppins(color: const Color(0xFF1976D2), fontWeight: FontWeight.w600),
          ),
        ),
      ));
    }

    return Column(children: children);
  }

  Widget _timelineRow({
    required String dateText,
    required String title,
    required String description,
    required StepState state,
    required bool showTopLine,
    required bool showBottomLine,
  }) {
    final Color dotColor;
    final Widget dotChild;
    switch (state) {
      case StepState.done:
        dotColor = const Color(0xFF2E7D32); // hijau
        dotChild = const Icon(Icons.check, size: 10, color: Colors.white);
        break;
      case StepState.progress:
        dotColor = const Color(0xFFFF8F00); // oranye
        dotChild = const SizedBox.shrink();
        break;
      case StepState.pending:
        dotColor = Colors.grey.shade400; // abu
        dotChild = const SizedBox.shrink();
        break;
    }

    final lineColor = Colors.grey.shade300;
    final titleColor = state == StepState.done
        ? const Color(0xFF2E7D32)
        : (state == StepState.progress ? const Color(0xFFFF8F00) : Colors.black87);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rail
          SizedBox(
            width: 24,
            child: Column(
              children: [
                if (showTopLine) Container(width: 2, height: 10, color: lineColor),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                  child: dotChild,
                ),
                if (showBottomLine) Container(width: 2, height: 40, color: lineColor),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateText, style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                const SizedBox(height: 2),
                Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: titleColor)),
                const SizedBox(height: 2),
                Text(description, style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ========================= Bottom Nav =========================

  Widget _bottomNavBar() {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == 0) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ServicePage()));
        } else if (index == 1) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const MarketplacePage()));
        } else if (index == 2) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomePage()));
        } else if (index == 3) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const TukarPoinPage()));
        } else if (index == 4) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProfilePage()));
        }
      },
      backgroundColor: Colors.blue,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.build_circle_outlined), label: 'Service'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart_outlined), label: 'Beli'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.percent_outlined), label: 'Promo'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
      ],
    );
  }
}

// ========================= Types util =========================

enum StepState { done, progress, pending }

class _TimelineItem {
  final DateTime? time;
  final String title;
  final String description;
  final StepState state;

  _TimelineItem({
    required this.time,
    required this.title,
    required this.description,
    required this.state,
  });
}

class _StatusMeta {
  final String title;
  final String description;
  _StatusMeta(this.title, this.description);
}