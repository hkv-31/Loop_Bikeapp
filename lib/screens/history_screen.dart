import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../models/models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Ride> _rides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final storageService = Provider.of<LocalStorageService>(context, listen: false);

    if (authService.currentUser != null) {
      final rides = await storageService.getUserRides(authService.currentUser!.id);
      setState(() {
        _rides = rides;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    if (authService.currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Ride History'),
          backgroundColor: Color(0xFF0D9A00),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'Please sign in to view history',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D9A00),
                  foregroundColor: Colors.white,
                ),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Ride History'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadRides,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF0D9A00)))
          : _rides.isEmpty
              ? _buildEmptyState()
              : _buildRideList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No ride history yet',
            style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Your completed rides will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0D9A00),
              foregroundColor: Colors.white,
            ),
            child: Text('Start Your First Ride'),
          ),
        ],
      ),
    );
  }

  Widget _buildRideList() {
    return RefreshIndicator(
      onRefresh: _loadRides,
      color: Color(0xFF0D9A00),
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _rides.length,
        itemBuilder: (context, index) {
          final ride = _rides[index];
          return _buildRideCard(ride);
        },
      ),
    );
  }

  Widget _buildRideCard(Ride ride) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    
    return Card(
      elevation: 3,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(ride.startTime),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(ride.paymentStatus),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    ride.paymentStatus.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            
            // Ride time
            Text(
              '${timeFormat.format(ride.startTime)} - ${ride.endTime != null ? timeFormat.format(ride.endTime!) : 'Ongoing'}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),
            
            // Ride metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildRideMetric('Duration', '${ride.duration} min'),
                _buildRideMetric('Distance', '${ride.distance.toStringAsFixed(1)} km'),
                _buildRideMetric('Cost', '₹${ride.cost.toStringAsFixed(0)}'),
              ],
            ),
            SizedBox(height: 12),
            
            // Payment details
            if (ride.stripePaymentId != null) ...[
              Divider(height: 1),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.receipt, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment ID: ${ride.stripePaymentId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            
            // Station info
            Divider(height: 20),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Color(0xFF0D9A00)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Station: ${_getStationName(ride.stationId)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideMetric(String label, String value) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Color(0xFF0D9A00).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D9A00),
              ),
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStationName(String stationId) {
    // In a real app, you'd fetch this from the database
    switch (stationId) {
      case '1': return 'Bandra Station West';
      case '2': return 'Bandra Bandstand';
      case '3': return 'Carter Road';
      case '4': return 'Linking Road';
      case '5': return 'Mount Mary Church';
      default: return 'Unknown Station';
    }
  }
}