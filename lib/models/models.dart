class UserModel {
  final String id;
  final String name;
  final String email;
  final DateTime createdAt;
  final bool hasSecurityDeposit;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
    this.hasSecurityDeposit = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'hasSecurityDeposit': hasSecurityDeposit ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      email: map['email'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      hasSecurityDeposit: map['hasSecurityDeposit'] == 1,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? createdAt,
    bool? hasSecurityDeposit,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      hasSecurityDeposit: hasSecurityDeposit ?? this.hasSecurityDeposit,
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
  final bool isCollege;

  BikeStation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.availableBikes,
    required this.totalCapacity,
    required this.address,
    this.isCollege = false,
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
      'isCollege': isCollege ? 1 : 0,
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
      isCollege: map['isCollege'] == 1,
    );
  }

  BikeStation copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    int? availableBikes,
    int? totalCapacity,
    String? address,
    bool? isCollege,
  }) {
    return BikeStation(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      availableBikes: availableBikes ?? this.availableBikes,
      totalCapacity: totalCapacity ?? this.totalCapacity,
      address: address ?? this.address,
      isCollege: isCollege ?? this.isCollege,
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