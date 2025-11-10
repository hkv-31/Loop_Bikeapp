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
      version: 3, // Increased version for schema update
      onCreate: _createTables,
      onUpgrade: (db, oldVersion, newVersion) async {
        // Handle database upgrades
        if (oldVersion < 2) {
          // Recreate tables if upgrading from very old version
          await db.execute('DROP TABLE IF EXISTS bike_stations');
          await db.execute('DROP TABLE IF EXISTS users');
          await db.execute('DROP TABLE IF EXISTS rides');
          await _createTables(db, newVersion);
        } else if (oldVersion < 3) {
          // Add new columns to existing tables
          await db.execute('''
            ALTER TABLE bike_stations ADD COLUMN isCollege INTEGER NOT NULL DEFAULT 0
          ''');
          await db.execute('''
            ALTER TABLE users ADD COLUMN hasSecurityDeposit INTEGER NOT NULL DEFAULT 0
          ''');
          // Re-insert sample stations with new schema
          await _insertSampleStations(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        createdAt INTEGER NOT NULL,
        hasSecurityDeposit INTEGER NOT NULL DEFAULT 0
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
        address TEXT NOT NULL,
        isCollege INTEGER NOT NULL DEFAULT 0
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

    // Insert sample bike stations including colleges
    await _insertSampleStations(db);
  }

  Future<void> _insertSampleStations(Database db) async {
    final stations = [
      // Original Bandra West stations
      BikeStation(
        id: '1',
        name: 'Bandra Station West',
        latitude: 19.0596,
        longitude: 72.8295,
        availableBikes: 5,
        totalCapacity: 10,
        address: 'Near Bandra Railway Station West, Bandra, Mumbai',
        isCollege: false,
      ),
      BikeStation(
        id: '2',
        name: 'Bandra Bandstand',
        latitude: 19.0519,
        longitude: 72.8223,
        availableBikes: 3,
        totalCapacity: 8,
        address: 'Bandra Bandstand Promenade, Bandra, Mumbai',
        isCollege: false,
      ),
      BikeStation(
        id: '3',
        name: 'Carter Road',
        latitude: 19.0542,
        longitude: 72.8261,
        availableBikes: 7,
        totalCapacity: 12,
        address: 'Carter Road Amphitheater, Bandra, Mumbai',
        isCollege: false,
      ),
      BikeStation(
        id: '4',
        name: 'Linking Road',
        latitude: 19.0528,
        longitude: 72.8327,
        availableBikes: 2,
        totalCapacity: 6,
        address: 'Linking Road Shopping District, Bandra, Mumbai',
        isCollege: false,
      ),
      BikeStation(
        id: '5',
        name: 'Mount Mary Church',
        latitude: 19.0419,
        longitude: 72.8236,
        availableBikes: 8,
        totalCapacity: 15,
        address: 'Mount Mary Church, Bandra, Mumbai',
        isCollege: false,
      ),
      
      // College Stations - Added for college presentation
      BikeStation(
        id: '6',
        name: 'Atlas Skilltech University - BKC',
        latitude: 19.0685,
        longitude: 72.8655,
        availableBikes: 6,
        totalCapacity: 12,
        address: 'Equinox Business Park, Bandra Kurla Complex, Mumbai',
        isCollege: true,
      ),
      BikeStation(
        id: '7',
        name: 'Jai Hind College - Churchgate',
        latitude: 18.9306,
        longitude: 72.8256,
        availableBikes: 4,
        totalCapacity: 8,
        address: 'A Road, Churchgate, Mumbai',
        isCollege: true,
      ),
      BikeStation(
        id: '8',
        name: 'HR College - Churchgate',
        latitude: 18.9320,
        longitude: 72.8263,
        availableBikes: 5,
        totalCapacity: 10,
        address: 'Dinshaw Wachha Road, Churchgate, Mumbai',
        isCollege: true,
      ),
      BikeStation(
        id: '9',
        name: 'Mithibai College - Vile Parle',
        latitude: 19.1028,
        longitude: 72.8498,
        availableBikes: 7,
        totalCapacity: 15,
        address: 'Vile Parle West, Mumbai',
        isCollege: true,
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

  Future<void> updateUserDepositStatus(String userId, bool hasDeposit) async {
    final db = await database;
    await db.update(
      'users',
      {'hasSecurityDeposit': hasDeposit ? 1 : 0},
      where: 'id = ?',
      whereArgs: [userId],
    );
    notifyListeners();
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