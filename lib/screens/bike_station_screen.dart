import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/location_service.dart';
import '../services/local_storage_service.dart';
import '../models/models.dart';
import 'nfc_unlock_screen.dart';

class BikeStationScreen extends StatelessWidget {
  final BikeStation station;

  const BikeStationScreen({Key? key, required this.station}) : super(key: key);

  void _openDirections(BuildContext context) {
    // For prototype, just show a dialog instead of launching URL
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Get Directions'),
        content: Text('Directions to ${station.name} would open in maps app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationService = Provider.of<LocationService>(context);
    double distance = 0.0;

    // Use the new latitude/longitude properties instead of currentPosition
    if (locationService.currentLatitude != null && locationService.currentLongitude != null) {
      distance = locationService.calculateDistance(
        locationService.currentLatitude!,
        locationService.currentLongitude!,
        station.latitude,
        station.longitude,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Station Details'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.directions),
            onPressed: () => _openDirections(context),
            tooltip: 'Get Directions',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Header
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Color(0xFF0D9A00), size: 24),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            station.name,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9A00),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      station.address,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Station Stats
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Available Bikes',
                      '${station.availableBikes}',
                      Icons.directions_bike,
                      station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
                    ),
                    _buildStatItem(
                      'Total Capacity',
                      '${station.totalCapacity}',
                      Icons.local_parking,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Distance',
                      '${distance.toStringAsFixed(1)} km',
                      Icons.place,
                      Colors.orange,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Availability Progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Bike Availability',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${station.availableBikes}/${station.totalCapacity}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: station.availableBikes / station.totalCapacity,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      station.availableBikes > 0 ? Color(0xFF0D9A00) : Colors.red,
                    ),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  SizedBox(height: 8),
                  Text(
                    station.availableBikes > 0 
                      ? '${station.availableBikes} bikes ready to ride!'
                      : 'All bikes are currently in use',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),

            // Unlock Button
            if (station.availableBikes > 0)
              ElevatedButton(
                onPressed: () {
                  // Update station availability
                  final storageService = Provider.of<LocalStorageService>(context, listen: false);
                  storageService.updateBikeStation(station.copyWith(
                    availableBikes: station.availableBikes - 1,
                  ));
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NfcUnlockScreen(station: station),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D9A00),
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
                    Icon(Icons.lock_open, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Unlock Bike',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    Icon(Icons.error_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'No bikes available',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check back later or try another station',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 8),
            
            // Safety Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF0D9A00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Color(0xFF0D9A00)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Always wear a helmet and follow traffic rules',
                      style: TextStyle(
                        color: Color(0xFF0D9A00),
                        fontSize: 12,
                      ),
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

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}