import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:stock_buddy/core/constants.dart';
import 'package:stock_buddy/providers/auth_provider.dart';
import 'package:stock_buddy/providers/disposal_provider.dart';
import 'package:stock_buddy/providers/items_provider.dart';
import 'package:stock_buddy/providers/location_provider.dart';
import 'package:stock_buddy/providers/repair_provider.dart';
import 'package:stock_buddy/providers/stock_provider.dart';
import 'package:stock_buddy/providers/stock_transfer_provider.dart';
import 'package:stock_buddy/providers/transaction_provider.dart';
import 'package:stock_buddy/providers/transfer_provider.dart';
import 'package:stock_buddy/providers/user_provider.dart';
import 'package:stock_buddy/screens/auth/login_screen.dart';
import 'package:stock_buddy/screens/home_screen.dart';
import 'package:stock_buddy/services/api_service.dart';
import 'package:stock_buddy/services/disposal_service.dart';
import 'package:stock_buddy/services/image_service.dart';
import 'package:stock_buddy/services/item_service.dart';
import 'package:stock_buddy/services/local_storage_service.dart';
import 'package:stock_buddy/services/location_service.dart';
import 'package:stock_buddy/services/repair_service.dart';
import 'package:stock_buddy/services/stock_service.dart';
import 'package:stock_buddy/services/stock_transfer_service.dart';
import 'package:stock_buddy/services/transaction_service.dart';
import 'package:stock_buddy/services/transfer_service.dart';
import 'package:stock_buddy/services/user_service.dart';

import 'SplashScreen.dart';
import 'firebase_options.dart';
import 'notification_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notifications and request permissions immediately
  final notificationServices = NotificationServices();
  await notificationServices.requestNotificationPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider(create: (_) => LocalStorageService()),
        Provider(create: (_) => ApiService(client: http.Client())),
        ChangeNotifierProvider(
          create: (context) => AuthProvider(
            apiService: context.read<ApiService>(),
            localStorageService: context.read<LocalStorageService>(),
          )..initialize(),
        ),
        Provider(
          create: (context) => ItemsService(
            client: http.Client(),
            getToken: () => context.read<LocalStorageService>().getAuthToken(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ItemsProvider(
            itemsService: context.read<ItemsService>(),
          ),
        ),
        ChangeNotifierProvider<TransactionProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final transactionService = TransactionService(
              baseUrl: ApiConstants.baseUrl,
              token: authProvider.token ?? '',
            );
            return TransactionProvider(transactionService: transactionService);
          },
        ),
        ChangeNotifierProvider<StockTransferProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final stockTransferService = StockTransferService(
              baseUrl: ApiConstants.baseUrl, // Replace with your actual API URL
              token: authProvider.token ?? '',
            );
            return StockTransferProvider(
                stockTransferService: stockTransferService);
          },
        ),
        ChangeNotifierProvider<TransferProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final transferService = TransferService(
              token: authProvider.token ?? '',
            );
            return TransferProvider(transferService);
          },
        ),
        ChangeNotifierProvider<RepairProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final repairService = RepairService(
              token: authProvider.token ?? '',
            );
            return RepairProvider(repairService);
          },
        ),
        ChangeNotifierProvider<DisposalProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final disposalService = DisposalService(
              token: authProvider.token ?? '',
            );
            return DisposalProvider(disposalService);
          },
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final userService = UserService(
              token: authProvider.token ?? '',
            );
            return UserProvider(userService);
          },
        ),
        ChangeNotifierProvider<StockProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final stockService = StockService(
              token: authProvider.token ?? '',
            );
            return StockProvider(stockService);
          },
        ),
        ChangeNotifierProvider<LocationProvider>(
          create: (context) {
            final authProvider = context.read<AuthProvider>();
            final locationService = LocationService(
              token: authProvider.token ?? '',
            );
            return LocationProvider(locationService);
          },
        ),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Stocky Buddy',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print(message.notification!.title.toString());
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  String? _errorMessage;
  String? token;
  DateTime? _authCheckStartTime;

  NotificationServices notificationServices = NotificationServices();

  @override
  void initState() {
    super.initState();
    _authCheckStartTime = DateTime.now();
    _checkAuthStatus();
    if (Platform.isIOS || Platform.isAndroid) {
      _setupNotifications();
    }
  }

  void _setupNotifications() {
    // Permission is now requested in main(), but we call it here too as a safety measure
    notificationServices.requestNotificationPermission();
    notificationServices.firebaseInit(context);
    notificationServices.isTokenRefresh();
    _fetchDeviceToken();
  }

  Future<void> _fetchDeviceToken() async {
    developer.log("_fetchDeviceToken() Run");
    final deviceToken = await notificationServices.getDeviceToken();
    setState(() {
      token = deviceToken;
    });
    developer.log("FCM Token: $token");
    print("FCM Token: $token");
  }

  Future<void> _checkAuthStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Initialize the auth provider
      await authProvider.initialize();

      // Check if we have a token locally first
      final hasLocalToken =
          authProvider.token != null && authProvider.token!.isNotEmpty;

      if (!hasLocalToken) {
        // No token found, user is not logged in
        await _ensureMinimumLoadingTime();
        if (mounted) {
          setState(() {
            _isLoggedIn = false;
            _isLoading = false;
          });
        }
        return;
      }

      // We have a token, verify it with the server
      final isValid = await authProvider.verifyToken();

      await _ensureMinimumLoadingTime();

      if (mounted) {
        setState(() {
          _isLoggedIn = isValid;
          _isLoading = false;
          _errorMessage =
              isValid ? null : 'Session expired. Please login again.';
        });
      }
    } catch (e) {
      print('Auth check error: $e');
      await _ensureMinimumLoadingTime();
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
          _errorMessage = 'Authentication check failed. Please login again.';
        });
      }
    }
  }

  Future<void> _ensureMinimumLoadingTime() async {
    if (_authCheckStartTime != null) {
      final elapsed = DateTime.now().difference(_authCheckStartTime!);
      final remaining = Duration(seconds: 3) - elapsed;

      if (remaining > Duration.zero) {
        await Future.delayed(remaining);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SplashScreen();
    }

    // Show error message if any (optional - you can remove this if you don't want to show errors)
    if (_errorMessage != null && !_isLoggedIn) {
      // You could show a dialog or snackbar here, or just navigate to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
