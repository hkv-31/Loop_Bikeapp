import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/payment_service.dart';
import '../models/models.dart';
import 'active_ride_screen.dart';

class NfcUnlockScreen extends StatefulWidget {
  final BikeStation station;

  const NfcUnlockScreen({super.key, required this.station});

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
  bool _checkingDeposit = true;
  bool _hasSecurityDeposit = false;
  bool _showingSafetyPopup = false;
  bool _processingDeposit = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _checkBluetoothStatus();
    _checkSecurityDeposit();
  }

  Future<void> _checkSecurityDeposit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    
    if (authService.currentUser != null) {
      final hasDeposit = await paymentService.checkSecurityDeposit(authService.currentUser!.id);
      setState(() {
        _hasSecurityDeposit = hasDeposit;
        _checkingDeposit = false;
      });
    } else {
      setState(() {
        _checkingDeposit = false;
      });
    }
  }

  Future<void> _checkBluetoothStatus() async {
    // Simulate Bluetooth check delay
    await Future.delayed(const Duration(seconds: 1));
    
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
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _bluetoothEnabled = true;
      _checkingBluetooth = false;
    });
  }

  Future<void> _paySecurityDeposit() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    
    if (authService.currentUser == null) return;

    setState(() {
      _processingDeposit = true;
    });

    final result = await paymentService.processSecurityDeposit(authService.currentUser!.id);

    setState(() {
      _processingDeposit = false;
    });

    if (result['success'] == true) {
      setState(() {
        _hasSecurityDeposit = true;
      });
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Security deposit paid successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSafetyPopup() {
    setState(() {
      _showingSafetyPopup = true;
    });
  }

  void _acceptSafetyTerms() {
    setState(() {
      _showingSafetyPopup = false;
    });
    _startNfcSimulation();
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
    await Future.delayed(const Duration(seconds: 2));

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
      await Future.delayed(const Duration(seconds: 1));
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

  void _startUnlockProcess() {
    if (!_hasSecurityDeposit) {
      // Show deposit required message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Security deposit required to unlock bike'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show safety popup before starting NFC
    _showSafetyPopup();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildSafetyPopup() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.withAlpha(30),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Safety First',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Safety Message
              const Text(
                'Important Safety Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Safety Points
              _buildSafetyPoint('Always wear a helmet while riding'),
              _buildSafetyPoint('Follow all traffic rules and signals'),
              _buildSafetyPoint('Use bike lanes where available'),
              _buildSafetyPoint('Be aware of your surroundings'),
              _buildSafetyPoint('Do not use mobile phone while riding'),
              
              const SizedBox(height: 16),
              
              // Incident Reporting
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Report any incidents or safety concerns immediately to LOOP support',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // T&C Link
              GestureDetector(
                onTap: () {
                  // Show T&C in dialog
                  showDialog(
                    context: context,
                    builder: (context) => _buildTermsAndConditionsDialog(),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Accept Button
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _acceptSafetyTerms,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9A00),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Accept & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, size: 16, color: Color(0xFF0D9A00)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsAndConditionsDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms & Conditions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTocSection(
                        'Liability Disclaimer',
                        'LOOP BikeShare provides bicycles as a service for urban mobility. Users acknowledge and agree that:',
                        [
                          'LOOP is not liable for any personal injury, accidents, or damages that occur during bike usage',
                          'Users are responsible for their own safety and must follow all traffic laws',
                          'Bike maintenance is performed regularly, but users should inspect bikes before use',
                          'Users assume all risks associated with bicycle riding in urban environments',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTocSection(
                        'Safety Responsibility',
                        'As a rider, you are responsible for:',
                        [
                          'Wearing appropriate safety gear including helmets',
                          'Following all traffic rules and regulations',
                          'Maintaining awareness of road conditions and other vehicles',
                          'Reporting any bike malfunctions or safety issues immediately',
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTocSection(
                        'Security Deposit',
                        'The ₹100 security deposit:',
                        [
                          'Is required before first bike unlock',
                          'Remains with LOOP for future rides',
                          'Covers potential damages or violations',
                          'Is non-refundable for administrative purposes',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D9A00),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('I Understand'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTocSection(String title, String description, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: Colors.grey)),
              Expanded(
                child: Text(
                  point,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    // Show safety popup if needed
    if (_showingSafetyPopup) {
      return _buildSafetyPopup();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Unlock Bike'),
        backgroundColor: const Color(0xFF0D9A00),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Security Deposit Status
              if (_checkingDeposit) ...[
                _buildDepositStatus(
                  'Checking Security Deposit...',
                  Icons.security,
                  Colors.blue,
                  'Verifying your account status',
                ),
              ] else if (!_hasSecurityDeposit) ...[
                _buildDepositStatus(
                  'Security Deposit Required',
                  Icons.payment,
                  Colors.orange,
                  '₹100 security deposit required before you can unlock bikes',
                ),
                const SizedBox(height: 24),
                if (_processingDeposit)
                  const CircularProgressIndicator(color: Color(0xFF0D9A00))
                else
                  ElevatedButton(
                    onPressed: _paySecurityDeposit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.payment, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Pay ₹100 Security Deposit',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ] else if (_checkingBluetooth) ...[
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
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _enableBluetooth,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                  ),
                  child: const Row(
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
              ] else if (_hasSecurityDeposit && _bluetoothEnabled) ...[
                // NFC Animation Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: _getStatusColor().withAlpha(25),
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
                                  color: const Color(0xFF0D9A00).withAlpha(51),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                size: 24,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
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
                const SizedBox(height: 40),

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
                const SizedBox(height: 16),

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
                const SizedBox(height: 8),

                // Status Badges
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, size: 16, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Security Deposit Paid',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blue),
                      ),
                      child: const Row(
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
                ),
              ],

              const SizedBox(height: 24),

              // Station Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.station.isCollege ? Icons.school : Icons.location_on,
                      color: const Color(0xFF0D9A00),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.station.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.station.address,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          if (widget.station.isCollege) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COLLEGE CAMPUS',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
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
              const SizedBox(height: 40),

              // Action Buttons
              if (!_checkingDeposit && !_checkingBluetooth && _hasSecurityDeposit && _bluetoothEnabled) ...[
                if (!_isScanning && !_scanComplete)
                  ElevatedButton(
                    onPressed: _startUnlockProcess,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9A00),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_open, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Start Ride & Unlock Bike',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                else if (_scanComplete && !_scanSuccess)
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: _startUnlockProcess,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Row(
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
                      const SizedBox(height: 12),
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
                const SizedBox(height: 30),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
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
      ),
    );
  }

  Widget _buildDepositStatus(String title, IconData icon, Color color, String subtitle) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(
            icon,
            size: 50,
            color: color,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (_checkingDeposit)
          CircularProgressIndicator(
            color: color,
            strokeWidth: 2,
          ),
      ],
    );
  }

  Widget _buildBluetoothStatus(String title, IconData icon, Color color, String subtitle) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 3),
          ),
          child: Icon(
            icon,
            size: 50,
            color: color,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[700],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        if (_checkingBluetooth)
          CircularProgressIndicator(
            color: color,
            strokeWidth: 2,
          ),
      ],
    );
  }

  Color _getStatusColor() {
    if (_isScanning) return const Color(0xFF0D9A00);
    if (_scanComplete) return _scanSuccess ? Colors.green : Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon() {
    if (_isScanning) return Icons.nfc;
    if (_scanComplete) return _scanSuccess ? Icons.check_circle : Icons.error;
    return Icons.lock_open;
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
    return 'Security deposit verified and Bluetooth connected.\nReady to start your ride safely.';
  }
}