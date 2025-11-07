import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/payment_service.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local database
  await LocalStorageService().initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => LocalStorageService()),
      ],
      child: MaterialApp(
        title: 'LOOP',
        theme: ThemeData(
          primaryColor: Color(0xFF0D9A00),
          colorScheme: ColorScheme.light(
            primary: Color(0xFF0D9A00),
            secondary: Color(0xFF0D9A00),
            background: Colors.white,
            onBackground: Colors.black,
          ),
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            backgroundColor: Color(0xFF0D9A00),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF0D9A00),
              foregroundColor: Colors.white,
            ),
          ),
          useMaterial3: true,
        ),
        home: AuthScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}