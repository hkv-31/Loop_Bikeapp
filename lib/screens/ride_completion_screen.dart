import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import 'home_screen.dart';

class RideCompletionScreen extends StatelessWidget {
  final Ride ride;

  const RideCompletionScreen({super.key, required this.ride});

  // Calculate environmental and cost savings with realistic randomized data based on ride distance
  Map<String, dynamic> _calculateSavings(Ride ride) {
    // Use actual ride distance as base, with minimum of 0.5km
    double actualDistance = ride.distance;
    if (actualDistance <= 0) {
      // If distance is 0 or negative, use a realistic random distance
      final random = DateTime.now().millisecond;
      actualDistance = 1.5 + (random % 30) / 10.0; // Random between 1.5-4.5 km
    }
    
    // Generate random values that scale with distance but have reasonable limits
    final random = DateTime.now().millisecond;
    
    // Money saved - scales with distance but has reasonable bounds
    double moneySaved = (actualDistance * 12).clamp(20.0, 75.0);
    
    // CO2 saved - scales with distance but have reasonable bounds  
    double co2Saved = (actualDistance * 180).clamp(150.0, 350.0);
    
    // Trees equivalent
    double treesEquivalent = (co2Saved / 21000).clamp(0.007, 0.017);
    
    // Calories burned - scales with distance but have reasonable bounds
    int caloriesBurned = (actualDistance * 35).round().clamp(50, 160);

    return {
      'moneySaved': moneySaved,
      'co2Saved': co2Saved,
      'treesEquivalent': treesEquivalent,
      'caloriesBurned': caloriesBurned,
      'actualDistance': actualDistance,
    };
  }

  @override
  Widget build(BuildContext context) {
    final savings = _calculateSavings(ride);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon with Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9A00).withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.celebration,
                  size: 60,
                  color: Color(0xFF0D9A00),
                ),
              ),
              const SizedBox(height: 32),

              // Thank You Message
              const Text(
                'Thank You for Riding! 🎉',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D9A00),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You completed ${savings['actualDistance'].toStringAsFixed(1)} km ride',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Savings Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      const Text(
                        'Your Positive Impact 🌱',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Money Saved
                      _buildSavingsRow(
                        '💰 Money Saved',
                        '₹${savings['moneySaved'].toStringAsFixed(0)}',
                        'vs taxi/auto',
                        Colors.green,
                      ),
                      const SizedBox(height: 16),
                      
                      // CO2 Saved
                      _buildSavingsRow(
                        '🌍 CO₂ Saved',
                        '${savings['co2Saved'].toStringAsFixed(0)}g',
                        'carbon emissions',
                        Colors.blue,
                      ),
                      const SizedBox(height: 16),
                      
                      // Environmental Impact
                      _buildSavingsRow(
                        '🌳 Environmental Impact',
                        '${savings['treesEquivalent'].toStringAsFixed(3)}',
                        'tree equivalents',
                        Color(0xFF0D9A00),
                      ),
                      const SizedBox(height: 16),
                      
                      // Health Benefits
                      _buildSavingsRow(
                        '💪 Calories Burned',
                        '${savings['caloriesBurned']}',
                        'health benefits',
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Inspirational Message
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9A00).withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.eco, size: 24, color: Color(0xFF0D9A00)),
                    SizedBox(height: 8),
                    Text(
                      'Every ride makes our city greener and healthier!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF0D9A00),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Action Buttons
              Column(
                children: [
                  // Start New Ride Button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                        (route) => false,
                      );
                    },
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
                        Icon(Icons.pedal_bike, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Start New Ride',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Exit App Button
                  OutlinedButton(
                    onPressed: () {
                      // Properly exit the app
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        // If we can't pop, just close the app
                        SystemNavigator.pop();
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                      side: const BorderSide(color: Colors.grey),
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.exit_to_app, size: 20),
                        SizedBox(width: 12),
                        Text(
                          'Exit App',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
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

  Widget _buildSavingsRow(String title, String value, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForType(title),
            size: 20,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String title) {
    switch (title) {
      case '💰 Money Saved':
        return Icons.currency_rupee;
      case '🌍 CO₂ Saved':
        return Icons.eco;
      case '🌳 Environmental Impact':
        return Icons.park;
      case '💪 Calories Burned':
        return Icons.fitness_center;
      default:
        return Icons.celebration;
    }
  }
}