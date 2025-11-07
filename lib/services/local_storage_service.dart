import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class LocalStorageService with ChangeNotifier {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'loop_bikeshare.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        createdAt INTEGER NOT NULL
      )
    ''');

    // Bike stations table
    await db.execute('''
      CREATE TABLE bike_stations(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        availableBikes INTEGER NOT NULL,
        totalCapacity INTEGER NOT NULL,
        address TEXT NOT NULL
      )
    ''');

    // Rides table
    await db.execute('''
      CREATE TABLE rides(
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        stationId TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER,
        distance REAL NOT NULL,
        duration INTEGER NOT NULL,
        cost REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        stripePaymentId TEXT,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insert sample bike stations in Bandra, Mumbai
    await _insertSampleStations(db);
  }

  Future<void> _insertSampleStations(Database db) async {
    final stations = [
      // Bandra West stations
      BikeStation(
        id: '1',
        name: 'Bandra Station West',
        latitude: 19.0596,
        longitude: 72.8295,
        availableBikes: 5,
        totalCapacity: 10,
        address: 'Near Bandra Railway Station West, Bandra, Mumbai',
      ),
      BikeStation(
        id: '2',
        name: 'Bandra Bandstand',
        latitude: 19.0519,
        longitude: 72.8223,
        availableBikes: 3,
        totalCapacity: 8,
        address: 'Bandra Bandstand Promenade, Bandra, Mumbai',
      ),
      BikeStation(
        id: '3',
        name: 'Carter Road',
        latitude: 19.0542,
        longitude: 72.8261,
        availableBikes: 7,
        totalCapacity: 12,
        address: 'Carter Road Amphitheater, Bandra, Mumbai',
      ),
      BikeStation(
        id: '4',
        name: 'Linking Road',
        latitude: 19.0528,
        longitude: 72.8327,
        availableBikes: 2,
        totalCapacity: 6,
        address: 'Linking Road Shopping District, Bandra, Mumbai',
      ),
      BikeStation(
        id: '5',
        name: 'Mount Mary Church',
        latitude: 19.0419,
        longitude: 72.8236,
        availableBikes: 8,
        totalCapacity: 15,
        address: 'Mount Mary Church, Bandra, Mumbai',
      ),
    ];

    for (var station in stations) {
      await db.insert('bike_stations', station.toMap(), 
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // User operations
  Future<void> saveUser(UserModel user) async {
    final db = await database;
    await db.insert('users', user.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<UserModel?> getUser(String id) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return UserModel.fromMap(maps.first);
    }
    return null;
  }

  // Bike station operations
  Future<List<BikeStation>> getBikeStations() async {
    final db = await database;
    final maps = await db.query('bike_stations');
    return maps.map((map) => BikeStation.fromMap(map)).toList();
  }

  Future<void> updateBikeStation(BikeStation station) async {
    final db = await database;
    await db.update(
      'bike_stations',
      station.toMap(),
      where: 'id = ?',
      whereArgs: [station.id],
    );
    notifyListeners();
  }

  // Ride operations
  Future<void> saveRide(Ride ride) async {
    final db = await database;
    await db.insert('rides', ride.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  Future<List<Ride>> getUserRides(String userId) async {
    final db = await database;
    final maps = await db.query(
      'rides',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'startTime DESC',
    );
    return maps.map((map) => Ride.fromMap(map)).toList();
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}