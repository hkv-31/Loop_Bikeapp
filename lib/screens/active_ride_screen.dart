import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import 'payment_screen.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _rideDuration = Duration.zero;
    _distanceTraveled = 0.0;
    _currentCost = 10.0; // Base fare ₹10
    _startTimer();
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
        }
      });
    });
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Ride Status Header
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.directions_bike,
                      size: 64,
                      color: Color(0xFF0D9A00),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ride in Progress',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D9A00),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Started from ${widget.station.name}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFF0D9A00).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Live Tracking Active',
                        style: TextStyle(
                          color: Color(0xFF0D9A00),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

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
                SizedBox(width: 12),
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
            SizedBox(height: 12),
            _buildMetricCard(
              'Current Cost',
              '₹${_currentCost.toStringAsFixed(0)}',
              Icons.currency_rupee,
              Color(0xFF0D9A00),
            ),
            SizedBox(height: 24),

            // Cost Breakdown
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt, color: Color(0xFF0D9A00)),
                        SizedBox(width: 8),
                        Text(
                          'Cost Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildCostRow('Base Fare', 10.0),
                    _buildCostRow('Distance (${_distanceTraveled.toStringAsFixed(1)} km × ₹5)', _distanceTraveled * 5),
                    _buildCostRow('Time (${_rideDuration.inMinutes} min × ₹0.5)', _rideDuration.inMinutes * 0.5),
                    Divider(thickness: 1),
                    _buildCostRow('Total Amount', _currentCost, isTotal: true),
                  ],
                ),
              ),
            ),
            Spacer(),

            // Safety Tips
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ride safely! Always follow traffic rules and wear a helmet.',
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
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Color(0xFF0D9A00) : Colors.black,
            ),
          ),
          Text(
            '₹${amount.toStringAsFixed(isTotal ? 0 : 2)}',
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Color(0xFF0D9A00) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}