import 'package:flutter/material.dart';
import '../models/models.dart';
import 'local_storage_service.dart';

class PaymentService with ChangeNotifier {
  bool _isProcessing = false;
  String? _error;

  bool get isProcessing => _isProcessing;
  String? get error => _error;

  // Security Deposit payment - ₹100 one-time payment
  Future<Map<String, dynamic>> processSecurityDeposit(String userId) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      // ALWAYS SUCCEED for demo
      final depositId = 'dep_${DateTime.now().millisecondsSinceEpoch}';
      
      // Update user deposit status in database
      final storage = LocalStorageService();
      await storage.updateUserDepositStatus(userId, true);
      
      _isProcessing = false;
      notifyListeners();
      
      return {
        'success': true,
        'paymentId': depositId,
        'amount': 100.0,
        'message': 'Security deposit payment successful',
      };
    } catch (e) {
      _isProcessing = false;
      _error = 'Deposit processing error: $e';
      notifyListeners();
      
      return {
        'success': false,
        'error': 'Deposit processing failed',
      };
    }
  }

  // Check if user has paid security deposit
  Future<bool> checkSecurityDeposit(String userId) async {
    try {
      final storage = LocalStorageService();
      final user = await storage.getUser(userId);
      return user?.hasSecurityDeposit ?? false;
    } catch (e) {
      return false;
    }
  }

  // Mock Stripe payment simulation for ride payments - ALWAYS SUCCEED
  Future<Map<String, dynamic>> processMockPayment(Ride ride) async {
    try {
      _isProcessing = true;
      _error = null;
      notifyListeners();

      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 3));

      // ALWAYS SUCCEED for demo
      final paymentId = 'pi_${DateTime.now().millisecondsSinceEpoch}';
      
      _isProcessing = false;
      notifyListeners();
      
      return {
        'success': true,
        'paymentId': paymentId,
        'message': 'Payment processed successfully',
      };
    } catch (e) {
      _isProcessing = false;
      _error = 'Payment processing error: $e';
      notifyListeners();
      
      return {
        'success': false,
        'error': 'Payment processing failed',
      };
    }
  }

  // Calculate ride cost based on distance and time
  double calculateRideCost(double distance, int duration) {
    const baseFare = 10.0; // ₹10 base fare
    const perKmRate = 5.0; // ₹5 per km
    const perMinuteRate = 0.5; // ₹0.5 per minute
    
    return baseFare + (distance * perKmRate) + (duration * perMinuteRate);
  }

  // Save ride with payment status
  Future<void> saveRideWithPayment(Ride ride, String paymentId) async {
    try {
      final storage = LocalStorageService();
      final rideWithPayment = Ride(
        id: ride.id,
        userId: ride.userId,
        stationId: ride.stationId,
        startTime: ride.startTime,
        endTime: ride.endTime,
        distance: ride.distance,
        duration: ride.duration,
        cost: ride.cost,
        paymentStatus: 'completed',
        stripePaymentId: paymentId,
      );
      
      await storage.saveRide(rideWithPayment);
    } catch (e) {
      throw Exception('Failed to save ride with payment: $e');
    }
  }
}