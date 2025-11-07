import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/local_storage_service.dart';
import '../models/models.dart';
import 'history_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Ride ride;

  const PaymentScreen({Key? key, required this.ride}) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _paymentSuccess = false;
  bool _paymentFailed = false;
  bool _isProcessing = false;
  String? _paymentId;

  @override
  void initState() {
    super.initState();
    _processPayment();
  }

  Future<void> _processPayment() async {
    final paymentService = Provider.of<PaymentService>(context, listen: false);
    
    setState(() {
      _isProcessing = true;
    });

    final result = await paymentService.processMockPayment(widget.ride);

    setState(() {
      _isProcessing = false;
      _paymentSuccess = result['success'] ?? false;
      _paymentFailed = !_paymentSuccess;
      _paymentId = result['paymentId'];
    });

    if (_paymentSuccess && _paymentId != null) {
      // Save the ride with payment info
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      await paymentService.saveRideWithPayment(widget.ride, _paymentId!);
    }
  }

  void _navigateToHistory() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HistoryScreen()),
      (route) => false,
    );
  }

  void _retryPayment() {
    setState(() {
      _paymentSuccess = false;
      _paymentFailed = false;
      _isProcessing = false;
      _paymentId = null;
    });
    _processPayment();
  }

  @override
  Widget build(BuildContext context) {
    final paymentService = Provider.of<PaymentService>(context);
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Ride Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Color(0xFF0D9A00)),
                        SizedBox(width: 8),
                        Text(
                          'Ride Summary',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildSummaryRow('Date & Time', dateFormat.format(widget.ride.startTime)),
                    _buildSummaryRow('Duration', '${widget.ride.duration} minutes'),
                    _buildSummaryRow('Distance', '${widget.ride.distance.toStringAsFixed(1)} km'),
                    Divider(thickness: 1),
                    _buildSummaryRow('Base Fare', '₹10'),
                    _buildSummaryRow('Distance Fare', '₹${(widget.ride.distance * 5).toStringAsFixed(0)}'),
                    _buildSummaryRow('Time Fare', '₹${(widget.ride.duration * 0.5).toStringAsFixed(0)}'),
                    Divider(thickness: 2),
                    _buildSummaryRow(
                      'Total Amount',
                      '₹${widget.ride.cost.toStringAsFixed(0)}',
                      isTotal: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            // Payment Status
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isProcessing)
                    _buildPaymentStatus(
                      'Processing Payment...',
                      Icons.payment,
                      Colors.blue,
                      'Please wait while we process your payment\nThis may take a few seconds',
                    )
                  else if (_paymentSuccess)
                    _buildPaymentStatus(
                      'Payment Successful!',
                      Icons.check_circle,
                      Colors.green,
                      'Your payment of ₹${widget.ride.cost.toStringAsFixed(0)} was successfully processed',
                    )
                  else if (_paymentFailed)
                    _buildPaymentStatus(
                      'Payment Failed',
                      Icons.error_outline,
                      Colors.red,
                      paymentService.error ?? 'Payment could not be processed\nPlease try again',
                    ),

                  SizedBox(height: 24),

                  if (_paymentSuccess) ...[
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Stripe Payment ID:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _paymentId ?? 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _navigateToHistory,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0D9A00),
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Ride History',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],

                  if (_paymentFailed) ...[
                    ElevatedButton(
                      onPressed: _retryPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Retry Payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 12),
                    TextButton(
                      onPressed: _navigateToHistory,
                      child: Text(
                        'Skip for Now',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
            value,
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

  Widget _buildPaymentStatus(String title, IconData icon, Color color, String subtitle) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
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
        ),
        SizedBox(height: 12),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}