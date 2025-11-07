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

    // Use the new latitude/longitude properties instead of currentPosition
    if (locationService.currentLatitude != null && locationService.currentLongitude != null) {
      setState(() {
        _currentLocation = LatLng(
          locationService.currentLatitude!,
          locationService.currentLongitude!,
        );
      });
      
      // Center map on user location
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
        title: Text('LOOP BikeShare'),
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
      body: Column(
        children: [
          // Interactive OpenStreetMap
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                center: LatLng(19.0540, 72.8302), // Bandra center
                zoom: 14.0,
                maxZoom: 18.0,
                minZoom: 10.0,
              ),
              children: [
                // OpenStreetMap Tile Layer
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.loop.bikeshare',
                ),
                // User Location Marker
                if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      builder: (ctx) => GestureDetector(
                        onTap: () {},
                        child: Container(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Bike Station Markers
                MarkerLayer(
                  markers: _stations.map((station) {
                    return Marker(
                      point: LatLng(station.latitude, station.longitude),
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
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            color: station.availableBikes > 0 
                                ? Color(0xFF0D9A00).withOpacity(0.9)
                                : Colors.red.withOpacity(0.9),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              station.availableBikes.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
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
                boxShadow: [
                  BoxShadow(
                    blurRadius: 4,
                    color: Colors.black12,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.pedal_bike, color: Color(0xFF0D9A00)),
                        SizedBox(width: 8),
                        Text(
                          'Nearby Bike Stations',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D9A00),
                          ),
                        ),
                        Spacer(),
                        Text(
                          '${_stations.length} stations',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _stations.isEmpty
                        ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9A00)))
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _stations.length,
                            itemBuilder: (context, index) {
                              final station = _stations[index];
                              return _buildStationListItem(station);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Action Button Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: ElevatedButton.icon(
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
                    SnackBar(content: Text('No stations found nearby')),
                  );
                }
              },
              icon: Icon(Icons.directions_bike),
              label: Text('Find Nearest Bike'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D9A00),
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
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

    return Card(
      margin: EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
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
        title: Text(
          station.name,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              station.address,
              style: TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_bike, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${station.availableBikes} bikes available',
                  style: TextStyle(fontSize: 11),
                ),
                SizedBox(width: 12),
                Icon(Icons.place, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${distance.toStringAsFixed(1)} km',
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            station.availableBikes > 0 ? 'Available' : 'Full',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BikeStationScreen(station: station),
            ),
          );
        },
      ),
    );
  }
}