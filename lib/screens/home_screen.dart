import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/local_storage_service.dart';
import '../models/models.dart';
import 'bike_station_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late MapController _mapController;
  List<BikeStation> _stations = [];
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final locationService = Provider.of<LocationService>(context, listen: false);
    await locationService.getCurrentLocation();
    
    final storageService = Provider.of<LocalStorageService>(context, listen: false);
    _stations = await storageService.getBikeStations();

    if (locationService.currentLatitude != null && locationService.currentLongitude != null) {
      setState(() {
        _currentLocation = LatLng(
          locationService.currentLatitude!,
          locationService.currentLongitude!,
        );
      });
      
      _mapController.move(_currentLocation!, 14.0);
    }

    setState(() {});
  }

  BikeStation? _findNearestStation() {
    if (_currentLocation == null || _stations.isEmpty) {
      return _stations.isNotEmpty ? _stations.first : null;
    }

    BikeStation? nearestStation;
    double? minDistance;

    final locationService = Provider.of<LocationService>(context, listen: false);

    for (var station in _stations) {
      final distance = locationService.calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        station.latitude,
        station.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
        nearestStation = station;
      }
    }

    return nearestStation;
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/app_logo.jpg',
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'LOOP BikeShare',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.my_location),
            onPressed: _centerMapOnLocation,
            tooltip: 'Center on my location',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Interactive OpenStreetMap
            Expanded(
              flex: 2,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  center: _currentLocation ?? LatLng(19.0540, 72.8302),
                  zoom: 14.0,
                  maxZoom: 18.0,
                  minZoom: 10.0,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.loop.bikeshare',
                  ),
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 40,
                          height: 40,
                          builder: (ctx) => Container(
                            child: Icon(
                              Icons.location_pin,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: _stations.map((station) {
                      return Marker(
                        point: LatLng(station.latitude, station.longitude),
                        width: 50,
                        height: 50,
                        builder: (ctx) => GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BikeStationScreen(station: station),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: station.availableBikes > 0 
                                  ? Color(0xFF0D9A00).withOpacity(0.9)
                                  : Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.pedal_bike,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  Text(
                                    station.availableBikes.toString(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Stations List Section
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 16,
                      color: Colors.black26,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Color(0xFF0D9A00).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.pedal_bike, color: Color(0xFF0D9A00), size: 20),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Nearby Stations',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${_stations.length}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D9A00),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Stations List
                    Expanded(
                      child: _stations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(color: Color(0xFF0D9A00)),
                                  SizedBox(height: 16),
                                  Text(
                                    'Loading stations...',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: ListView.builder(
                                padding: EdgeInsets.only(bottom: 16),
                                itemCount: _stations.length,
                                itemBuilder: (context, index) {
                                  final station = _stations[index];
                                  return _buildStationListItem(station);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Button Section
            Container(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Quick Stats
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildQuickStat('Total Stations', _stations.length.toString()),
                        _buildQuickStat('Available Bikes', 
                          _stations.fold(0, (sum, station) => sum + station.availableBikes).toString()),
                        _buildQuickStat('Nearest', 
                          _findNearestStation()?.availableBikes.toString() ?? '0'),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Action Button
                  ElevatedButton.icon(
                    onPressed: () {
                      final nearestStation = _findNearestStation();
                      if (nearestStation != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BikeStationScreen(station: nearestStation),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('No stations found nearby'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.electric_bike, size: 24),
                    label: Text(
                      'Find Nearest Bike',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D9A00),
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: Color(0xFF0D9A00).withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _centerMapOnLocation() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 14.0);
    } else {
      _initializeData();
    }
  }

  Widget _buildStationListItem(BikeStation station) {
    final locationService = Provider.of<LocationService>(context);
    double distance = _currentLocation != null
        ? locationService.calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            station.latitude,
            station.longitude,
          )
        : 0.0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BikeStationScreen(station: station),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Availability Indicator
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: station.availableBikes > 0 
                        ? Color(0xFF0D9A00).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.pedal_bike,
                    color: station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                
                // Station Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        station.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        station.address,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          _buildInfoChip(
                            '${station.availableBikes} bikes',
                            Icons.directions_bike,
                            station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
                          ),
                          SizedBox(width: 8),
                          _buildInfoChip(
                            '${distance.toStringAsFixed(1)} km',
                            Icons.place,
                            Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Status Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: station.availableBikes > 0 
                        ? Color(0xFF0D9A00).withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    station.availableBikes > 0 ? 'Available' : 'Full',
                    style: TextStyle(
                      color: station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D9A00),
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}