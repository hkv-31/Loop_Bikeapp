class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}

class BikeStation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int availableBikes;
  final int totalCapacity;
  final String address;

  BikeStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.availableBikes,
    required this.totalCapacity,
    required this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'availableBikes': availableBikes,
      'totalCapacity': totalCapacity,
      'address': address,
    };
  }

  factory BikeStation.fromMap(Map<String, dynamic> map) {
    return BikeStation(
      id: map['id'],
      name: map['name'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      availableBikes: map['availableBikes'],
      totalCapacity: map['totalCapacity'],
      address: map['address'],
    );
  }

  BikeStation copyWith({
    int? availableBikes,
  }) {
    return BikeStation(
      id: id,
      name: name,
      latitude: latitude,
      longitude: longitude,
      availableBikes: availableBikes ?? this.availableBikes,
      totalCapacity: totalCapacity,
      address: address,
    );
  }
}

class Ride {
  final String id;
  final String userId;
  final String stationId;
  final DateTime startTime;
  final DateTime? endTime;
  final double distance;
  final int duration;
  final double cost;
  final String paymentStatus;
  final String? stripePaymentId;

  Ride({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.startTime,
    this.endTime,
    required this.distance,
    required this.duration,
    required this.cost,
    required this.paymentStatus,
    this.stripePaymentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'stationId': stationId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'distance': distance,
      'duration': duration,
      'cost': cost,
      'paymentStatus': paymentStatus,
      'stripePaymentId': stripePaymentId,
    };
  }

  factory Ride.fromMap(Map<String, dynamic> map) {
    return Ride(
      id: map['id'],
      userId: map['userId'],
      stationId: map['stationId'],
      startTime: DateTime.fromMillisecondsSinceEpoch(map['startTime']),
      endTime: map['endTime'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['endTime'])
          : null,
      distance: map['distance'],
      duration: map['duration'],
      cost: map['cost'],
      paymentStatus: map['paymentStatus'],
      stripePaymentId: map['stripePaymentId'],
    );
  }
}