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

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
  }

  Future<void> _startNfcSimulation() async {
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
            // NFC Animation Container
            AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
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
                              color: Color(0xFF0D9A00).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: Icon(
                      _getStatusIcon(),
                      size: 64,
                      color: _getStatusColor(),
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

            // Station Info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
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
    return 'Press the button below to simulate NFC unlock.\nMake sure Bluetooth is enabled.';
  }
}