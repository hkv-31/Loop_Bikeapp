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
  int _selectedPaymentMethod = 0; // 0: Card, 1: UPI, 2: Net Banking
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _upiIdController = TextEditingController();
  String? _paymentError;

  @override
  void initState() {
    super.initState();
    // Pre-fill demo data
    _cardNumberController.text = '4242 4242 4242 4242';
    _expiryController.text = '12/25';
    _cvvController.text = '123';
    _nameController.text = 'John Doe';
    _upiIdController.text = 'john.doe@okicici';
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

Future<void> _processPayment() async {
  final paymentService = Provider.of<PaymentService>(context, listen: false);
  
  setState(() {
    _isProcessing = true;
    _paymentError = null;
  });

  final result = await paymentService.processMockPayment(widget.ride);

  setState(() {
    _isProcessing = false;
    _paymentSuccess = result['success'] ?? false;
    _paymentFailed = !_paymentSuccess;
    _paymentId = result['paymentId'];
    _paymentError = result['error'];
  });

  if (_paymentSuccess && _paymentId != null) {
    // Save the ride with payment info using Provider
    final storageService = Provider.of<LocalStorageService>(context, listen: false);
    
    // Create the paid ride object directly
    final paidRide = Ride(
      id: widget.ride.id,
      userId: widget.ride.userId,
      stationId: widget.ride.stationId,
      startTime: widget.ride.startTime,
      endTime: widget.ride.endTime,
      distance: widget.ride.distance,
      duration: widget.ride.duration,
      cost: widget.ride.cost,
      paymentStatus: 'completed',
      stripePaymentId: _paymentId!,
    );
    
    await storageService.saveRide(paidRide);
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
      _paymentError = null;
    });
    _processPayment();
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            _buildPaymentMethodOption(
              0,
              'Credit/Debit Card',
              Icons.credit_card,
              Colors.blue,
            ),
            _buildPaymentMethodOption(
              1,
              'UPI',
              Icons.payment,
              Colors.purple,
            ),
            _buildPaymentMethodOption(
              2,
              'Net Banking',
              Icons.account_balance,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(int index, String title, IconData icon, Color color) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _selectedPaymentMethod == index ? color.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _selectedPaymentMethod == index ? color : Colors.grey[300]!,
        ),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title),
        trailing: _selectedPaymentMethod == index
            ? Icon(Icons.check_circle, color: color)
            : null,
        onTap: () {
          setState(() {
            _selectedPaymentMethod = index;
          });
        },
      ),
    );
  }

  Widget _buildCardPaymentForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Card Number',
                hintText: '4242 4242 4242 4242',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'John Doe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiPaymentForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPI Payment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _upiIdController,
              decoration: InputDecoration(
                labelText: 'UPI ID',
                hintText: 'yourname@upi',
                prefixIcon: Icon(Icons.payment),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You will be redirected to your UPI app for payment',
                      style: TextStyle(
                        color: Colors.orange[700],
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

  Widget _buildNetBankingForm() {
    final banks = [
      'State Bank of India',
      'HDFC Bank',
      'ICICI Bank',
      'Axis Bank',
      'Punjab National Bank',
      'Bank of Baroda',
    ];

    String? selectedBank;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Banking',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Bank',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              value: selectedBank,
              items: banks.map((String bank) {
                return DropdownMenuItem<String>(
                  value: bank,
                  child: Text(bank),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedBank = newValue;
                });
              },
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.security, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Secure net banking gateway. You will be redirected to your bank\'s website.',
                      style: TextStyle(
                        color: Colors.blue[700],
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

  Widget _buildPaymentButton() {
    String buttonText;
    Color buttonColor;

    switch (_selectedPaymentMethod) {
      case 0:
        buttonText = 'Pay with Card';
        buttonColor = Colors.blue;
        break;
      case 1:
        buttonText = 'Pay with UPI';
        buttonColor = Colors.purple;
        break;
      case 2:
        buttonText = 'Pay with Net Banking';
        buttonColor = Colors.green;
        break;
      default:
        buttonText = 'Pay Now';
        buttonColor = Color(0xFF0D9A00);
    }

    return ElevatedButton(
      onPressed: _isProcessing ? null : _processPayment,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: _isProcessing
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Processing...'),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 20),
                SizedBox(width: 12),
                Text(
                  buttonText,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Color(0xFF0D9A00),
        foregroundColor: Colors.white,
      ),
      body: _isProcessing || _paymentSuccess || _paymentFailed
          ? _buildPaymentStatus()
          : SingleChildScrollView(
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

                  // Payment Methods
                  _buildPaymentMethodSelector(),
                  SizedBox(height: 16),

                  // Payment Form based on selection
                  if (_selectedPaymentMethod == 0) _buildCardPaymentForm(),
                  if (_selectedPaymentMethod == 1) _buildUpiPaymentForm(),
                  if (_selectedPaymentMethod == 2) _buildNetBankingForm(),
                  SizedBox(height: 24),

                  // Security Badge
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user, color: Colors.green, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Secure Payment',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              Text(
                                'Your payment information is encrypted and secure',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),

                  // Pay Button
                  _buildPaymentButton(),
                  SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildPaymentStatus() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_isProcessing)
            _buildPaymentStatusCard(
              'Processing Payment...',
              Icons.payment,
              Colors.blue,
              'Please wait while we process your payment\nThis may take a few seconds',
            )
          else if (_paymentSuccess)
            _buildPaymentStatusCard(
              'Payment Successful!',
              Icons.check_circle,
              Colors.green,
              'Your payment of ₹${widget.ride.cost.toStringAsFixed(0)} was successfully processed',
            )
          else if (_paymentFailed)
            _buildPaymentStatusCard(
              'Payment Failed',
              Icons.error_outline,
              Colors.red,
              _paymentError ?? 'Payment could not be processed\nPlease try again',
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
    );
  }

  Widget _buildPaymentStatusCard(String title, IconData icon, Color color, String subtitle) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: color.withAlpha(25),
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
}