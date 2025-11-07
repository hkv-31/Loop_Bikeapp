import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/models.dart';
import 'active_ride_screen.dart';

class NfcUnlockScreen extends StatefulWidget {
  final BikeStation station;

  const NfcUnlockScreen({Key? key, required this.station}) : super(key: key);

  @override
  _NfcUnlockScreenState createState() => _NfcUnlockScreenState();
}

class _NfcUnlockScreenState extends State<NfcUnlockScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isScanning = false;
  bool _scanComplete = false;
  bool _scanSuccess = false;
  bool _bluetoothEnabled = false;
  bool _checkingBluetooth = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _checkBluetoothStatus();
  }

  Future<void> _checkBluetoothStatus() async {
    // Simulate Bluetooth check delay
    await Future.delayed(Duration(seconds: 1));
    
    // For demo, 80% chance Bluetooth is enabled
    final isEnabled = DateTime.now().millisecond % 10 < 8;
    
    setState(() {
      _bluetoothEnabled = isEnabled;
      _checkingBluetooth = false;
    });
  }

  Future<void> _enableBluetooth() async {
    setState(() {
      _checkingBluetooth = true;
    });

    // Simulate enabling Bluetooth
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _bluetoothEnabled = true;
      _checkingBluetooth = false;
    });
  }

  Future<void> _startNfcSimulation() async {
    if (!_bluetoothEnabled) return;

    setState(() {
      _isScanning = true;
      _scanComplete = false;
      _scanSuccess = false;
    });

    _animationController.repeat(reverse: true);

    // Simulate NFC scanning process
    await Future.delayed(Duration(seconds: 2));

    // 90% success rate for demo
    final isSuccess = DateTime.now().millisecond % 10 != 0;

    _animationController.stop();
    
    setState(() {
      _isScanning = false;
      _scanComplete = true;
      _scanSuccess = isSuccess;
    });

    // Navigate on success
    if (isSuccess) {
      await Future.delayed(Duration(seconds: 1));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveRideScreen(station: widget.station),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Unlock Bike'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bluetooth Status Indicator
            if (_checkingBluetooth) ...[
              _buildBluetoothStatus(
                'Checking Bluetooth...',
                Icons.bluetooth_searching,
                Colors.blue,
                'Verifying Bluetooth connectivity',
              ),
            ] else if (!_bluetoothEnabled) ...[
              _buildBluetoothStatus(
                'Bluetooth Required',
                Icons.bluetooth_disabled,
                Colors.orange,
                'Bluetooth is required for NFC bike unlock',
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enableBluetooth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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
                    Icon(Icons.bluetooth, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Enable Bluetooth',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // NFC Animation Container
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: _getStatusColor().withAlpha(25), // 0.1 opacity equivalent
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getStatusColor(),
                    width: 4,
                  ),
                ),
                child: Stack(
                  children: [
                    if (_isScanning)
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Center(
                            child: Container(
                              width: 100 + (_animationController.value * 60),
                              height: 100 + (_animationController.value * 60),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D9A00).withAlpha(51), // 0.2 opacity equivalent
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth_connected,
                            size: 32,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 8),
                          Icon(
                            _getStatusIcon(),
                            size: 48,
                            color: _getStatusColor(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),

              // Status Text
              Text(
                _getStatusText(),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),

              // Instructions
              Text(
                _getStatusSubtext(),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),

              // Bluetooth Connected Badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(25), // 0.1 opacity equivalent
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bluetooth_connected, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Bluetooth Connected',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 24),

            // Station Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(25), // 0.1 opacity equivalent
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: Color(0xFF0D9A00), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.station.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.station.address,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40),

            // Action Buttons
            if (!_checkingBluetooth && _bluetoothEnabled) ...[
              if (!_isScanning && !_scanComplete)
                ElevatedButton(
                  onPressed: _startNfcSimulation,
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
                      Icon(Icons.nfc, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Tap to Simulate NFC',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else if (_scanComplete && !_scanSuccess)
                Column(
                  children: [
                    ElevatedButton(
                      onPressed: _startNfcSimulation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.refresh, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Try Again',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Back to Station',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
            ],

            // User Info
            if (authService.currentUser != null) ...[
              SizedBox(height: 30),
              Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Text(
                    'Logged in as: ${authService.currentUser!.name}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBluetoothStatus(String title, IconData icon, Color color, String subtitle) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withAlpha(25), // 0.1 opacity equivalent
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(
            icon,
            size: 50,
            color: color,
          ),
        ),
        SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        if (_checkingBluetooth)
          CircularProgressIndicator(
            color: color,
            strokeWidth: 2,
          ),
      ],
    );
  }

  Color _getStatusColor() {
    if (_isScanning) return Color(0xFF0D9A00);
    if (_scanComplete) return _scanSuccess ? Colors.green : Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isScanning) return Icons.nfc;
    if (_scanComplete) return _scanSuccess ? Icons.check_circle : Icons.error;
    return Icons.nfc_outlined;
  }

  String _getStatusText() {
    if (_isScanning) return 'Scanning...';
    if (_scanComplete) return _scanSuccess ? 'Bike Unlocked!' : 'Scan Failed';
    return 'Ready to Unlock';
  }

  String _getStatusSubtext() {
    if (_isScanning) return 'Hold your phone near the bike\'s NFC tag\nScanning in progress...';
    if (_scanComplete) {
      return _scanSuccess 
          ? 'Your bike is unlocked and ready to ride!\nYou can now start your journey.'
          : 'Unable to connect to the bike.\nPlease try again or select another bike.';
    }
    return 'Bluetooth is connected and ready.\nPress the button to simulate NFC unlock.';
  }
}