import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/models.dart';
import 'payment_screen.dart';
import 'dart:async';
import 'dart:math' as math;

class ActiveRideScreen extends StatefulWidget {
  final BikeStation station;

  const ActiveRideScreen({Key? key, required this.station}) : super(key: key);

  @override
  _ActiveRideScreenState createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  late DateTime _startTime;
  late Duration _rideDuration;
  late double _distanceTraveled;
  late double _currentCost;
  Timer? _timer;
  int _secondsElapsed = 0;
  late MapController _mapController;
  List<LatLng> _routePoints = [];
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _rideDuration = Duration.zero;
    _distanceTraveled = 0.0;
    _currentCost = 10.0; // Base fare ₹10
    _mapController = MapController();
    _initializeMapAndRoute();
    _startTimer();
  }

  void _initializeMapAndRoute() {
    final locationService = Provider.of<LocationService>(context, listen: false);
    
    // Set current location
    if (locationService.currentLatitude != null && locationService.currentLongitude != null) {
      _currentLocation = LatLng(
        locationService.currentLatitude!,
        locationService.currentLongitude!,
      );
    } else {
      // Fallback to station location
      _currentLocation = LatLng(widget.station.latitude, widget.station.longitude);
    }

    // Generate sample route points (in real app, this would come from a routing service)
    _generateSampleRoute();
    
    // Center map on current location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_currentLocation != null) {
        _mapController.move(_currentLocation!, 15.0);
      }
    });
  }

  void _generateSampleRoute() {
    if (_currentLocation == null) return;

    // Generate a sample circular route around the current location for demo
    _routePoints = [];
    final centerLat = _currentLocation!.latitude;
    final centerLng = _currentLocation!.longitude;
    
    // Create a circular route (in real app, this would be actual road routes)
    for (int i = 0; i <= 360; i += 10) {
      double angle = i * (math.pi / 180);
      double lat = centerLat + 0.005 * math.cos(angle);
      double lng = centerLng + 0.005 * math.sin(angle);
      _routePoints.add(LatLng(lat, lng));
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
        _rideDuration = Duration(seconds: _secondsElapsed);
        
        // Simulate distance: 0.1 km every 30 seconds (approx 12 km/h)
        if (_secondsElapsed % 30 == 0) {
          _distanceTraveled += 0.1;
          _updateCost();
          _updateUserPositionOnRoute();
        }
      });
    });
  }

  void _updateUserPositionOnRoute() {
    if (_routePoints.isNotEmpty) {
      // Simulate user moving along the route
      int routeIndex = (_secondsElapsed ~/ 10) % _routePoints.length;
      setState(() {
        _currentLocation = _routePoints[routeIndex];
      });
    }
  }

  void _updateCost() {
    const baseFare = 10.0;
    const perKmRate = 5.0;
    const perMinuteRate = 0.5;
    
    _currentCost = baseFare + 
                  (_distanceTraveled * perKmRate) + 
                  (_secondsElapsed / 60 * perMinuteRate);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  void _endRide() {
    _timer?.cancel();
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Create ride object
    final ride = Ride(
      id: 'ride_${DateTime.now().millisecondsSinceEpoch}',
      userId: authService.currentUser!.id,
      stationId: widget.station.id,
      startTime: _startTime,
      endTime: DateTime.now(),
      distance: _distanceTraveled,
      duration: _rideDuration.inMinutes,
      cost: _currentCost,
      paymentStatus: 'pending',
      stripePaymentId: null,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(ride: ride),
      ),
    );
  }

  void _emergencyStop() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Emergency Stop'),
        content: Text('Are you sure you want to stop the ride immediately? This will end your current ride.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _endRide();
            },
            child: Text(
              'Stop Ride',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _centerMapOnUser() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Active Ride'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _centerMapOnUser,
            tooltip: 'Center on my location',
          ),
          IconButton(
            icon: Icon(Icons.warning),
            onPressed: _emergencyStop,
            tooltip: 'Emergency Stop',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Map Section - Fixed height
            Container(
              height: MediaQuery.of(context).size.height * 0.4, // 40% of screen
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _currentLocation ?? LatLng(widget.station.latitude, widget.station.longitude),
                      zoom: 15.0,
                      maxZoom: 18.0,
                      minZoom: 10.0,
                      interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.loop.bikeshare',
                      ),
                      
                      // Route Polyline
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              color: Color(0xFF0D9A00).withAlpha(150),
                              strokeWidth: 6.0,
                            ),
                          ],
                        ),
                      
                      // User Location Marker
                      if (_currentLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _currentLocation!,
                              width: 40,
                              height: 40,
                              builder: (ctx) => Container(
                                child: Icon(
                                  Icons.directions_bike,
                                  color: Colors.blue,
                                  size: 40,
                                ),
                              ),
                            ),
                          ],
                        ),
                      
                      // Start Station Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(widget.station.latitude, widget.station.longitude),
                            width: 30,
                            height: 30,
                            builder: (ctx) => Container(
                              child: Icon(
                                Icons.location_pin,
                                color: Colors.green,
                                size: 30,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  // Map Controls Overlay
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      children: [
                        // Navigation Info Card
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.navigation, size: 16, color: Color(0xFF0D9A00)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Navigation Active',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF0D9A00),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Following suggested route',
                                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Ride Information Section - Scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ride Status Header
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_bike,
                              size: 48,
                              color: Color(0xFF0D9A00),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Ride in Progress',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9A00),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Started from ${widget.station.name}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D9A00).withAlpha(25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Live Tracking Active',
                                style: TextStyle(
                                  color: Color(0xFF0D9A00),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),

                    // Ride Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Duration',
                            _formatDuration(_rideDuration),
                            Icons.timer,
                            Colors.blue,
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            'Distance',
                            '${_distanceTraveled.toStringAsFixed(1)} km',
                            Icons.space_dashboard,
                            Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'Current Cost',
                            '₹${_currentCost.toStringAsFixed(0)}',
                            Icons.currency_rupee,
                            Color(0xFF0D9A00),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            'Speed',
                            '12 km/h',
                            Icons.speed,
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Quick Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _centerMapOnUser,
                            icon: Icon(Icons.my_location, size: 16),
                            label: Text('Center Map'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Color(0xFF0D9A00),
                              side: BorderSide(color: Color(0xFF0D9A00)),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Show route information
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Route Information'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Suggested bike route active'),
                                      SizedBox(height: 8),
                                      Text('• Distance: ${_distanceTraveled.toStringAsFixed(1)} km'),
                                      Text('• Duration: ${_formatDuration(_rideDuration)}'),
                                      Text('• Bike-friendly roads'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            icon: Icon(Icons.route, size: 16),
                            label: Text('Route Info'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Safety Tips
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security, color: Colors.blue, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Follow the green route for bike-friendly roads',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),

                    // End Ride Button
                    ElevatedButton(
                      onPressed: _endRide,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.stop, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'End Ride',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}